#!/bin/bash

islocked=$(/usr/sbin/ioreg -n Root -d1 | grep IOConsoleLocked | awk -F \= '{print $2}')

if [ $islocked == "No" ]; then
 echo "$(date) Pinging Citrix" >> /Users/tomas.rakuscinec/citrix.txt
 osascript -e 'tell application "Keyboard Maestro Engine" to do script "688157E5-5312-4DF0-9CF4-A383920CF40C"'
else
 echo "$(date) Screen is Locked, not Pinging Citrix" | tee -a /Users/tomas.rakuscinec/citrix.txt
fi
