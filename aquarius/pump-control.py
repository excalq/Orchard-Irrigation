import os
import asyncio
import click
import datetime
import logging
import paho.mqtt.client as mqtt
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

MQTT_HOST = os.getenv('MQTT_HOST')
MQTT_USERNAME = os.getenv('MQTT_USERNAME')
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD')
MQTT_PORT = int(os.getenv('MQTT_PORT', 1883))

class MQTTHandler:
    def __init__(self, mqtt_client):
        self.mqtt_client = mqtt_client
        self.topic_values = {}

    async def get_topic_value(self, topic, timeout=60):
        # Wait until the topic value is available or timeout occurs
        for _ in range(timeout):
            if topic in self.topic_values:
                return self.topic_values[topic]
            await asyncio.sleep(1)
        return None  # Return None if the value wasn't received in time

    def on_message(self, client, userdata, msg):
        # Store the received value in the topic_values dictionary
        logging.debug('Received message: %s', msg.payload.decode())
        self.topic_values[msg.topic] = msg.payload.decode()

    async def subscribe_and_wait(self, topics):
        # Subscribe to all required topics and wait for values
        for topic in topics:
            logging.debug('Subscribing to topic: %s', topic)
            self.mqtt_client.subscribe(topic)
        self.mqtt_client.on_message = self.on_message
        await asyncio.gather(*(self.get_topic_value(topic) for topic in topics))

class PumpController:
    # Irrigation thresholds
    SOLAR_PUMP_IRRADIANCE_THRESHOLD = 420 # W/m^2
    AC_PUMP_SOC_THRESHOLD = 70 # Percent state of charge
    AC_PUMP_POWER_THRESHOLD = 800 # active charging Watts

    def __init__(self, mqtt_handler):
        self.mqtt_handler = mqtt_handler

    async def select_pump(self):
        # List of topics to subscribe to
        topics = [
            'irrigation/solar-well-pump/status',
            'weather/station/solarradiation',
            'zigbee2mqtt/irrigation/ac-well-pump/availability',
            'battery-stats/Soc',
            'battery-stats/Power'
        ]
        
        # Subscribe and wait for all values to be received
        logging.debug('Subscribing to MQTT topics. Please wait...')
        await self.mqtt_handler.subscribe_and_wait(topics)
        logging.debug('All MQTT topics received.')

        # Fetch the relevant values from the received MQTT messages
        solar_pump_status = int(self.mqtt_handler.topic_values.get('irrigation/solar-well-pump/status', 0))
        solar_radiation = float(self.mqtt_handler.topic_values.get('weather/station/solarradiation', 0))
        ac_pump_lwt = self.mqtt_handler.topic_values.get('zigbee2mqtt/irrigation/ac-well-pump/availability', '{"state":"offline"}')
        battery_soc = float(self.mqtt_handler.topic_values.get('battery-stats/Soc', 0))
        battery_power = float(self.mqtt_handler.topic_values.get('battery-stats/Power', 0))

        # Determine which pump to use
        if solar_pump_status == 1 and solar_radiation > self.SOLAR_PUMP_IRRADIANCE_THRESHOLD:
            return 'solar-pump'
        elif ac_pump_lwt == '{"state":"online"}' and (battery_soc > self.AC_PUMP_SOC_THRESHOLD or battery_power > self.AC_PUMP_POWER_THRESHOLD):
            return 'ac-pump'
        else:
            logging.info('No pump selected. '
                'Solar pump status: %d, Solar radiation: %.2f, AC pump LWT: %s, Battery SOC: %.2f, Battery power: %.2f',
                solar_pump_status, solar_radiation, ac_pump_lwt, battery_soc, battery_power)
            return 'no-pump'

    def activate_pump(self, pump):
        # First, Turn off all pumps
        self.deactivate_pump('solar-pump')
        self.deactivate_pump('ac-pump')
        # Activate the selected pump
        if pump == 'solar-pump':
            self.mqtt_handler.mqtt_client.publish('irrigation/solar-well-pump/relay/0/set', 'ON')
        elif pump == 'ac-pump':
            self.mqtt_handler.mqtt_client.publish('zigbee2mqtt/irrigation/ac-well-pump/set/state', 'ON')
        
        # Publish which pump is active (or if no pump is active)
        self.mqtt_handler.mqtt_client.publish('irrigation/active-well-pump', pump)

    def deactivate_pump(self, pump):
        if pump == 'solar-pump':
            self.mqtt_handler.mqtt_client.publish('irrigation/solar-well-pump/relay/0/set', 'OFF')
        elif pump == 'ac-pump':
            self.mqtt_handler.mqtt_client.publish('zigbee2mqtt/irrigation/ac-well-pump/set/state', 'OFF')
        else:
            self.deactivate_pump('solar-pump')
            self.deactivate_pump('ac-pump')
        
        # Publish that no pump is active
        self.mqtt_handler.mqtt_client.publish('irrigation/active-well-pump', 'no-pump')

def get_date():
    return datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

@click.command()
@click.option('--pump', type=click.Choice(['solar-pump', 'ac-pump'], case_sensitive=False), help="Specify which pump to control.")
@click.argument('action', type=click.Choice(['on', 'off'], case_sensitive=False))
def main(pump, action):
    logging.basicConfig(level=logging.INFO)

    async def run():
        # Initialize MQTT client
        mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        mqtt_client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        mqtt_client.connect(MQTT_HOST, MQTT_PORT, 60)
        mqtt_client.loop_start()

        # Initialize MQTT handler and pump controller
        mqtt_handler = MQTTHandler(mqtt_client)
        pump_controller = PumpController(mqtt_handler)

        if action == 'on':
            if pump:
                pump_controller.activate_pump(pump)
                logging.info(f"Pump {pump} turned on.")
            else:
                # Select pump based on solar/battery state and activate it
                selected_pump = await pump_controller.select_pump()
                logging.info(f"Selected pump: {selected_pump}")
                if selected_pump != 'no-pump':
                    pump_controller.activate_pump(selected_pump)
        else:
            if pump:
                pump_controller.deactivate_pump(pump)
                logging.info(f"Pump {pump} turned off.")
            else:
                # Turn off all pumps
                pump_controller.deactivate_pump('solar-pump')
                pump_controller.deactivate_pump('ac-pump')
                logging.info("All pumps turned off.")

        mqtt_client.loop_stop()
        mqtt_client.disconnect()

    asyncio.run(run())

# Run the main function
if __name__ == '__main__':
    main()
