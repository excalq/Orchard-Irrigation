#!/bin/bash
cd $(dirname $0); source .env

## NOC HVAC (Box Fan or AC) Triggering
# Run this minutely in crontab
TEMP_LIMIT=80 # In F, Above this temp, turn fan/AC on
SOC_LIMIT=75 # INT
RECOV_MIN_WATTS=1400  # Is system charging at >= this wattage

# Observe Battery SoC, charging Watts, and temp
mosquitto_sub -h $MQTT_HOST -u $MQTT_USERNAME -P $MQTT_PASSWORD -W 60 -C 1 -t "battery-stats/Soc" > /tmp/battery.soc &
mosquitto_sub -h $MQTT_HOST -u $MQTT_USERNAME -P $MQTT_PASSWORD -W 60 -C 1 -t "battery-stats/Power" > /tmp/battery.watts &
mosquitto_sub -h $MQTT_HOST -u $MQTT_USERNAME -P $MQTT_PASSWORD -W 60 -C 1 -t "weather/station/temp2f" > /tmp/battery.temp &

wait
battery_soc=$(</tmp/battery.soc)
battery_watts=$(</tmp/battery.watts)
battery_temp=$(</tmp/battery.temp)

# Bash can't do float comparisons, so `%.*` drops the decimal
if [[ "${battery_temp%.*}" -ge "$[TEMP_LIMIT%.*}" && ("${battery_soc%.*}" -ge "${SOC_LIMIT%.*}" || "${battery_watts%.*}" -ge "${RECOV_MIN_WATTS%.*}") ]]; then 
	echo "$(date +'%F %T') ACTIVATING NOC FAN. Temp is ${battery_temp}°, Soc is ${battery_soc}%." | tee -a $HOME/DcPowerMonitor/noc-ac.log
	mosquitto_pub -t 'hvac/noc/ac/cmnd/POWER' -m 'ON' -u $MQTT_USERNAME -P $MQTT_PASSWORD
else
	mosquitto_pub -t 'hvac/noc/ac/cmnd/POWER' -m 'OFF' -u $MQTT_USERNAME -P $MQTT_PASSWORD
	echo "$(date +'%F %T') Turn off NOC FAN. Temp is ${battery_temp}°, Soc is ${battery_soc}%." | tee -a $HOME/DcPowerMonitor/noc-ac.log
fi
