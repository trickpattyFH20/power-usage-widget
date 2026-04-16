# power-usage-widget

![License](https://img.shields.io/badge/license-MIT-blue)
![Plasma](https://img.shields.io/badge/KDE_Plasma-6.0%2B-blue)

<a href="https://www.buymeacoffee.com/trickylf"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=trickylf&button_colour=BD5FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00" /></a>

Displays your current power usage in watts in the Plasma panel.
The widget reads battery telemetry directly from `/sys/class/power_supply` (either `power_now` or `current_now` × `voltage_now`), averages samples over a configurable window, and updates a compact label. Options include font size, side padding, sample/refresh rate, and hiding while plugged into AC.

### Development

#### Install
kpackagetool6 --type Plasma/Applet --install .

#### Uninstall
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.powerusage