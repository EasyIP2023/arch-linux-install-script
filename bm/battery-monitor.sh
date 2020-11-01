#!/bin/bash

# Get current battery precentage 
bat_level=$(acpi -b |cut -d "," -f2| sed 's/%//g')

# charging is 1 if charging and 0 if discharging
charging=$(acpi -b| grep -c "Charging")

# While the battery is charging and charged is up to 80%
[[ $charging -eq 1 && $bat_level -gt 80 ]] && espeak "Battery at $bat_level precent, Remove your charger" -p 90 -s 130 2>/dev/null

# While the battery is not charging and it goes below 20%
[[ $charging -eq 0 && $bat_level -lt 20 ]] && espeak "Battery at $bat_level precent, Connect the charger" -p 90 -s 130 2>/dev/null

exit 0
