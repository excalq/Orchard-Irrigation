import json
import logging
import paho.mqtt.client as mqtt
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

LOCAL_PREFIX = "battery-stats/"
topics = {
    "ConsumedAmphours": f"N/{CERBO_ID}/system/0/Dc/Battery/ConsumedAmphours",
    "Soc":              f"N/{CERBO_ID}/system/0/Dc/Battery/Soc",
    "Voltage":          f"N/{CERBO_ID}/system/0/Dc/Battery/Voltage",
    "Current":          f"N/{CERBO_ID}/system/0/Dc/Battery/Current",
    "Power":            f"N/{CERBO_ID}/system/0/Dc/Battery/Power", 
}

def update_topic(client, local_topic, value):
    if local_topic in topics.keys():
        dest_topic = f"{LOCAL_PREFIX}{local_topic}"
        result = client.publish(dest_topic, value)
        #print(result[0])
        print(f"Published {value} to {dest_topic}")

def on_message(client, userdata, message):
    payload = message.payload.decode("utf-8")
    try:
        data = json.loads(payload)
        value = data.get('value')
        if value is not None: 
            # Extract the topic name from the incoming message topic
            for local_topic,victron_topic in topics.items():
                if victron_topic == message.topic:
                    value = round(value, 1)
                    update_topic(userdata['dest_client'], local_topic, value)
                    break
    except Exception as e: 
        logging.exception(e)
        print(f"Unexpected value: {data}")
    
dest_client = mqtt.Client()
dest_client.username_pw_set(MQTT_USERNAME,MQTT_PASSWORD)
dest_client.connect(MQTT_HOST, 1883, 60)

victron = mqtt.Client()
victron.user_data_set({'dest_client': dest_client})
victron.connect(VICTRON_HOST, 1883, 60)

# Subscribe to all the topics defined in the dictionary
for topic in topics.values():
    victron.subscribe(topic)

victron.on_message = on_message

victron.loop_forever()

