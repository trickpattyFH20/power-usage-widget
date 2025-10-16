# power-usage-widget

Displays your current power usage in watts in the Plasma panel.
The widget reads battery telemetry directly from `/sys/class/power_supply` (either `power_now` or `current_now` × `voltage_now`), averages samples over a configurable window, and updates a compact label. Options include font size, side padding, sample/refresh rate, and hiding while plugged into AC.

### Development

#### Install
kpackagetool6 --type Plasma/Applet --install .

#### Uninstall
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.powerusage