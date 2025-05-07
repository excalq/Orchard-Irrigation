#!/bin/bash
cd $(dirname $0); source .env

vesta () {
	mosquitto_pub -t 'irrigation/bees-knees/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

ceres () {
	mosquitto_pub -t 'irrigation/cats-meow/relay/2/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

luna () {
	mosquitto_pub -t 'irrigation/cats-meow/relay/0/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

jupiter () {
	mosquitto_pub -t 'irrigation/bees-knees/relay/3/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

saturn () {
	mosquitto_pub -t 'irrigation/bees-knees/relay/2/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

uranus () {
	mosquitto_pub -t 'irrigation/bees-knees/relay/1/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

neptune () {
	mosquitto_pub -t 'irrigation/cats-meow/relay/3/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
}

kuiper () {
	mosquitto_pub -t 'irrigation/cats-meow/relay/1/set' -m "$1" -u $MQTT_USERNAME -P $MQTT_PASSWORD 
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

# 2023.08.22: Leave one sprinkler on to prevent pump-stuck overpressure event
if [[ $1 == "off" ]]; then
	echo "$(date +'%F %T'): Powering Off Irrigation." >> /home/kiot/DcPowerMonitor/quick-irrigation.log
	solarpump "OFF"
	luna 1
	ceres 0
	vesta 0
	kuiper 0
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "OFF"
elif [[ $1 == "luna" ]]; then
	log "Luna"
	luna 1
	sleep 2 
	ceres 0
	vesta 0
	kuiper 0
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "ON"
elif [[ $1 == "vesta" ]]; then
	log "Vesta"
	vesta 1
	sleep 2 
	luna 0
	# ceres 0
	kuiper 0
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "ON"
elif [[ $1 == "ceres" ]]; then
	log "Ceres"
	ceres 1
	sleep 2 
	luna 0
	# vesta 0
	kuiper 0
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "ON"
elif [[ $1 == "kuiper" ]]; then
	log "Mars"
	kuiper 1
	sleep 2 
	luna 0
	ceres 0
	vesta 0
	jupiter 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "ON"
elif [[ $1 == "jupiter" ]]; then
	log "Jupiter"
	jupiter 1
	sleep 2
	luna 0
	ceres 0
	vesta 0
	kuiper 0
	saturn 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "ON"
elif [[ $1 == "saturn" ]]; then
	log "Saturn"
	saturn 1
	sleep 2 
	luna 0
	ceres 0
	vesta 0
	kuiper 0
	jupiter 0
	uranus 0
	neptune 0
	sleep 2 
	solarpump "ON"
elif [[ $1 == "uranus" ]]; then
	log "Uranus"
	uranus 1
	sleep 2
	luna 0
	ceres 0
	vesta 0
	kuiper 0
	jupiter 0
	saturn 0
	neptune 0
	sleep 2
	solarpump "ON"
elif [[ $1 == "neptune" ]]; then
	log "Neptune"
	neptune 1
	sleep 2
	luna 0
	ceres 0
	vesta 0
	kuiper 0
	jupiter 0
	saturn 0
	uranus 0
	sleep 2 
	solarpump "ON"
# The jet pump over-pressurizes and cycles when drip zones are solo
elif [[ $1 == "all-drips" ]]; then
	log "Saturn + Uranus + Neptune + Kuiper"
	ceres 0
	vesta 0
	luna 0
	saturn 1
	uranus 1
	neptune 1
	kuiper 1
	sleep 2
	luna 0
	ceres 0
	vesta 0
	jupiter 0
	sleep 2 
	solarpump "ON"
fi

