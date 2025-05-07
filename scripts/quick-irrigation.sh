#!/bin/bash
# V2 - inner-planet names 2025
# V1 - using outer-planet names pre-2025

# dynamic, solarpump, jetpump
ACTIVE_PUMP=dynamic # Uses solar/battery status to determine pump
# ACTIVE_PUMP=solarpump

cd $(dirname $0); source .env

# Note on ordering: Controllers are mounted with  90° rotation, so for intuitive L->R
# button order, the relays are in descending "planetary order". (Relays: 3 2 1 0)

## Drip Zones
mercury () { # was jupiter
	mosquitto_pub -t 'irrigation/bees-knees/relay/3/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

venus () { # was saturn
	mosquitto_pub -t 'irrigation/bees-knees/relay/2/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

earth() { # was uranus
	mosquitto_pub -t 'irrigation/bees-knees/relay/1/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

mars () { # was vesta 
	mosquitto_pub -t 'irrigation/bees-knees/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

# TODO: Add outer planets as future zones/splits

## Sprinkler Zones
moon () { # was neptune
	mosquitto_pub -t 'irrigation/cats-meow/relay/3/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

ceres () {
	mosquitto_pub -t 'irrigation/cats-meow/relay/2/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

pluto () { # was luna
	mosquitto_pub -t 'irrigation/cats-meow/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

jupiter () { # kuiper
	mosquitto_pub -t 'irrigation/cats-meow/relay/1/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

## Pumps
solarpump () {
	mosquitto_pub -t 'irrigation/solar-well-pump/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

jetpump () {
	mosquitto_pub -t 'wellhouse-pumps/cmnd/POWER1' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

dynamic () {
	python3 /home/kiot/IotMonitoringApps/aquarius/pump-control.py $1
}

log () {
	echo "$(date +'%F %T'): Activating zone $1" >> /home/kiot/DcPowerMonitor/quick-irrigation.log 
}

# 2023.08.22: Leave one sprinkler on to prevent pump-stuck overpressure event
# Why so much repetion? Allows triggering multiple combinations of zones together. Irrigation isn't DRY, heh
if [[ $1 == "off" ]]; then
	echo "$(date +'%F %T'): Powering Off Irrigation." >> /home/kiot/DcPowerMonitor/quick-irrigation.log
	$ACTIVE_PUMP "OFF"
	moon 1
elif [[ $1 == "mercury" ]]; then
	log "Mercury"
	mercury 1
	sleep 2 
	venus 0
	earth 0
	mars 0
	moon 0
	ceres 0
	jupiter 0
	pluto 0	
	sleep 2
	$ACTIVE_PUMP "ON"
elif [[ $1 == "venus" ]]; then
	log "Venus"
	venus 1
	sleep 2 
	mercury 0
	earth 0
	mars 0
	moon 0
	ceres 0
	jupiter 0
	pluto 0
	sleep 2 
	$ACTIVE_PUMP "ON"
elif [[ $1 == "earth" ]]; then
	log "Earth"
	earth 1
	sleep 2 
	$ACTIVE_PUMP "ON"
	mercury 0
	venus 0
	mars 0
	moon 0
	ceres 0
	jupiter 0
	pluto 0
elif [[ $1 == "mars" ]]; then
	log "Mars"
	mars 1
	sleep 2 
	mercury 0
	venus 0
	earth 0
	moon 0
	ceres 0
	jupiter 0
	pluto 0
	sleep 2 
	$ACTIVE_PUMP "ON"
elif [[ $1 == "moon" ]]; then
	log "Moon"
	moon 1
	sleep 2 
	mercury 0
	venus 0
	earth 0
	ceres 0
	jupiter 0
	pluto 0
	sleep 2 
	$ACTIVE_PUMP "ON"
elif [[ $1 == "ceres" ]]; then
	log "Ceres"
	ceres 1
	sleep 2
	mercury 0
	venus 0
	earth 0
	moon 0
	jupiter 0
	pluto 0
	sleep 2
	$ACTIVE_PUMP "ON"
elif [[ $1 == "jupiter" ]]; then
	log "Jupiter"
	jupiter 1
	sleep 2
	mercury 0
	venus 0
	earth 0
	mars 0
	moon 0
	ceres 0
	pluto 0
	sleep 2 
	$ACTIVE_PUMP "ON"
elif [[ $1 == "pluto" ]]; then
	log "Pluto"
	pluto 1
	sleep 2 
	mercury 0
	venus 0
	earth 0
	mars 0
	moon 0
	ceres 0
	jupiter 0
	sleep 2 
	$ACTIVE_PUMP "ON"
elif [[ $1 == "all-drips" ]]; then
	log "Mercury + Venus + Earth + Mars"
	mercury 1
	venus 1
	earth 1
	mars 1
	moon 0
	ceres 0
	jupiter 0
	pluto 0
	sleep 2 
	$ACTIVE_PUMP "ON"
fi

