#!/bin/bash
cd $(dirname $0); source .env

mars () {
	mosquitto_pub -t 'irrigation/inner-planets-sonoff/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD # Mars
}

jupiter () {
	mosquitto_pub -t 'irrigation/outer-planets-sonoff/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD # Mars
}

saturn () {
	mosquitto_pub -t 'irrigation/outer-planets-sonoff/relay/1/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD # Mars
}

uranus () {
	mosquitto_pub -t 'irrigation/outer-planets-sonoff/relay/2/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD # Mars
}

neptune () {
	mosquitto_pub -t 'irrigation/outer-planets-sonoff/relay/3/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD # Mars
}

solarpump () {
	mosquitto_pub -t 'irrigation/solar-well-pump/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

jetpump () {
	mosquitto_pub -t 'wellhouse-pumps/cmnd/POWER1' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD
}

log () {
	echo "$(date +'%F %T'): Activating zone $1" >> /home/kiot/DcPowerMonitor/quick-irrigation.log 
}

if [[ $1 == "off" ]]; then
	echo "$(date +'%F %T'): Powering Off Irrigation." >> /home/kiot/DcPowerMonitor/quick-irrigation.log
	jetpump "OFF"
	mars 0
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
elif [[ $1 == "mars" ]]; then
	log "Mars"
	mars 1
	sleep 2 
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	jetpump "ON"
elif [[ $1 == "jupiter" ]]; then
	log "Jupiter"
	jupiter 1
	sleep 2
	mars 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	jetpump "ON"
elif [[ $1 == "saturn" ]]; then
	log "Saturn"
	saturn 1
	sleep 2 
	mars 0
	jupiter 0
	uranus 0
	neptune 0
	sleep 2 
	jetpump "ON"
elif [[ $1 == "uranus" ]]; then
	log "Uranus"
	uranus 1
	sleep 2
	mars 0
	jupiter 0
	saturn 0
	neptune 0
	sleep 2
	jetpump "ON"
elif [[ $1 == "neptune" ]]; then
	log "Neptune"
	neptune 1
	sleep 2
	mars 0
	jupiter 0
	saturn 0
	uranus 0
	sleep 2 
	jetpump "ON"
# The jet pump over-pressurizes and cycles when drip zones are solo
elif [[ $1 == "all-drips" ]]; then
	log "Saturn + Uranus + Neptune"
	saturn 1
	uranus 1
	neptune 1
	sleep 2
	mars 0
	jupiter 0
	sleep 2 
	jetpump "ON"
fi

