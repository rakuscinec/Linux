#!/bin/bash

function screenIsLocked { [ "$(/usr/libexec/PlistBuddy -c "print :IOConsoleUsers:0:CGSSessionScreenIsLocked" /dev/stdin 2>/dev/null <<< "$(ioreg -n Root -d1 -a)")" = "true" ] && return 0 || return 1; }
function screenIsUnlocked { [ "$(/usr/libexec/PlistBuddy -c "print :IOConsoleUsers:0:CGSSessionScreenIsLocked" /dev/stdin 2>/dev/null <<< "$(ioreg -n Root -d1 -a)")" != "true" ] && return 0 || return 1; }

if screenIsUnlocked; then
	if pgrep -x "Citrix Viewer" > /dev/null; then
		echo "$(date) Citrix Running" >> /Users/tomas.rakuscinec/citrix.txt
		osascript -e 'tell application "Keyboard Maestro Engine" to do script "688157E5-5312-4DF0-9CF4-A383920CF40C"'

	fi
fi
