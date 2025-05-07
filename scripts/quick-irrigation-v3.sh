#!/bin/bash
# V3 - refactored with assoc array, DRY up
# V2 - inner-planet names 2025
# V1 - using outer-planet names pre-2025
cd $(dirname $0); source .env

# dynamic, solarpump, jetpump
ACTIVE_PUMP=dynamic # Uses solar/battery status to determine pump
LOG_FILE="$HOME/DcPowerMonitor/quick-irrigation.log"
MQTT_AUTH="-u $MQTT_USERNAME -P $MQTT_PASSWORD"

## Irrigation Zones (controller+relay for each valve)
# Note on ordering: Controllers are mounted with 90° rotation, so for intuitive L->R
# button order, the relays are in descending "planetary order". (Relays: 3 2 1 0)
declare -A ZONES=(
  ["mercury"]="bees-knees/relay/3"  # drip
    ["venus"]="bees-knees/relay/2"  # drip
    ["earth"]="bees-knees/relay/1"  # drip
     ["mars"]="bees-knees/relay/0"  # drip
      ["moon"]="cats-meow/relay/3"  # sprinkler
     ["ceres"]="cats-meow/relay/2"  # sprinkler
   ["jupiter"]="cats-meow/relay/1"  # sprinkler
     ["pluto"]="cats-meow/relay/0"  # sprinkler
)

# Activate the pump given by configuration
activate_pump() {
  case $ACTIVE_PUMP in
    solarpump)
      mosquitto_pub -t 'irrigation/solar-well-pump/relay/0/set' -m "ON" $MQTT_AUTH
      ;;
    jetpump)
      mosquitto_pub -t 'zigbee2mqtt/irrigation/ac-well-pump/set/stat' -m "ON" $MQTT_AUTH
      ;;
    dynamic)
      python3 $HOME/IotMonitoringApps/aquarius/pump-control.py ON
      ;;
  esac
}

# Ensure ALL pumps have been shutdown
shutdown_pumps() {
    mosquitto_pub -t 'irrigation/solar-well-pump/relay/0/set' -m "OFF" $MQTT_AUTH
    mosquitto_pub -t 'zigbee2mqtt/irrigation/ac-well-pump/set/state' -m "OFF" $MQTT_AUTH
}

activate_zone() {
  local zone=$1
  local state=$2
  local controller_relay=${ZONES[$zone]}

  if [[ -n $controller_relay ]]; then
    mosquitto_pub -t "irrigation/${controller_relay}/set" -m "$state" $MQTT_AUTH
  fi
}

activate_single_zone() {
  local active_zone=$1

  # Log activation
  echo "$(date +'%F %T'): Activating zone $active_zone" >> $LOG_FILE

  # Activate zone
  activate_zone $active_zone 1
  sleep 2

  # Once active, close other zones
  for zone in "${!ZONES[@]}"; do
    if [[ $zone != $active_zone ]]; then
      activate_zone $zone 0
    fi
  done
}

shutdown_all_zones() {
  for zone in "${!ZONES[@]}"; do
    activate_zone $zone 0
  done
}

# Handle Argument Cases
case $1 in
  "mercury"|"venus"|"earth"|"mars"|"moon"|"ceres"|"jupiter"|"pluto")
    activate_single_zone $1
    sleep 2
    activate_pump
    ;;

  "off")
    echo "$(date +'%F %T'): Powering Off Irrigation." >> $LOG_FILE
    shutdown_pumps
    shutdown_all_zones

    # Leave one zone on to prevent overpressure events if pump activates
    activate_single_zone "mercury" 1
    ;;

  "all-drips")
    echo "$(date +'%F %T'): Activating zone Mercury + Venus + Earth + Mars" >> $LOG_FILE

    # Turn on all drip zones
    activate_zone "mercury" 1
    activate_zone "venus" 1
    activate_zone "earth" 1
    activate_zone "mars" 1

    # Turn off sprinkler zones
    activate_zone "moon" 0
    activate_zone "ceres" 0
    activate_zone "jupiter" 0
    activate_zone "pluto" 0

    sleep 2
    activate_pump
    ;;


  *)
    echo "Usage: $0 {zone|all-drips|off}"
    echo "Zones: mercury, venus, earth, mars, moon, ceres, jupiter, pluto"
    exit 1
    ;;
esac
