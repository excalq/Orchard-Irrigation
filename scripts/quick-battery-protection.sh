#!/bin/bash
cd $(dirname $0); source .env

# Run this minutely in crontab
SOC_LIMIT=60   # POSITIVE FLOAT
RECOV_MIN_WATTS=800  # Is system charging at >= this wattage

function high_soc() {
    $MQTT_USERNAME "BEGIN {exit !($(mosquitto_sub -h $VICTRON_HOST -W 40 -t \"N/$VICTRON_ID/system/0/Dc/Battery/Soc\" -C 1 | jq '.value') >= $SOC_LIMIT )}"
}

function is_charging() {
    $MQTT_USERNAME "BEGIN {exit !($(mosquitto_sub -h $VICTRON_HOST -W 40 -t \"N/$VICTRON_ID/system/0/Dc/Battery/Power\" -C 1 | jq '.value') >= $RECOV_MIN_WATTS )}"
}

# Observe Battery SoC and Charging Watts
mosquitto_sub -h $VICTRON_HOST -W 20 -t "N/$VICTRON_ID/system/0/Dc/Battery/Soc" -C 1 | jq '.value' > /tmp/battery.soc &
mosquitto_sub -h $VICTRON_HOST -W 20 -t "N/$VICTRON_ID/system/0/Dc/Battery/Power" -C 1 | jq '.value' > /tmp/battery.watts &
# Trigger MQTT publish
mosquitto_pub -h $VICTRON_HOST -t "R/$VICTRON_ID/keepalive" -m ''

wait
battery_soc=$(</tmp/battery.soc)
battery_watts=$(</tmp/battery.watts)

if [[ "$battery_soc" -ge "$SOC_LIMIT" || "$battery_watts" -ge "$RECOV_MIN_WATTS" ]]; then 
	#echo "POWER OK" >> /home/kiot/DcPowerMonitor/quick-battery-protection.log
	:
else
	printf '%d\n' $?
	echo "$(date +'%F %T') BATTERY BANK LOW. POWERING DOWN PUMP" >> /home/kiot/DcPowerMonitor/quick-battery-protection.log
	mosquitto_pub -t 'wellhouse-pumps/cmnd/POWER1' -m 'OFF' -u $MQTT_USERNAME -P $MQTT_PASSWORD
fi
