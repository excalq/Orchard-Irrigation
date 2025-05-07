#!/bin/bash
cd $(dirname $0); source .env
mosquitto_pub -t 'irrigation/manifold-flow-monitor/reset' -m "" -u $MQTT_USERNAME -P $MQTT_PASSWORD
