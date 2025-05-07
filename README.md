# Orchard IoT Scripts

These Scripts (Bash and a bit of Python) serve as the automation code for my hobbist orchard.

This orchard is off-grid, and uses two pumps, one a Solar Direct piston pump, and another is an
AC jet pump, running off mains power.

The irrigation zones consist of 8 valves, on two Sonoff 4Ch Pro Smart Relay Devices.

They are managed by `crontab` on a Raspberry Pi, triggering the zone and select pump scripts as configured.
