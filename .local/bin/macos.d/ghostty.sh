#!/bin/bash
# https://www.macscripter.net/t/how-to-use-passed-arguments-in-apple-script/73668/3

osa='
on runCommandInteractively(theCommand)
	tell me to makeNewWindow()
	tell application "System Events"
		keystroke ((" " & theCommand) as text)
		keystroke return
	end tell
end runCommandInteractively

-- runCommandInteractively("echo ohai && sleep 5 && exit")

on makeNewWindow()
	if application "Ghostty" is running then
		tell application "System Events"
			set visible of application process "Ghostty" to true
			delay 0.1
		end tell
	end if

	tell application "Ghostty" to activate

	tell application "System Events"
		set preWindowCount to count of windows of application process "Ghostty"
		keystroke "n" using command down
		set tryUntil to (current date) + 5
		repeat while preWindowCount is not less than (count of windows of application process "Ghostty")
			delay 0.1
			if tryUntil is less than (current date) then
				error "whoops"
			end if
		end repeat
	end tell
end makeNewWindow

on activateOrMakeNewWindow()
	if application "Ghostty" is running then
		tell application "System Events"
			set visible of application process "Ghostty" to true
			delay 0.1
		end tell
	end if

	tell application "Ghostty" to activate

	tell application "System Events"
		if 0 is equal to (count of windows of application process "Ghostty") then
			tell me to makeNewWindow()
		end if
	end tell
end activateOrMakeNewWindow

-- activateOrMakeNewWindow()
on run args
if class of args is list then -- arguments passed come in as a list
		set quotedArgs to {}
		repeat with arg in args
			-- set end of quotedArgs to "'"'"'" & arg & "'"'"'"
			set end of quotedArgs to "" & arg
		end repeat

    set AppleScript'"'"'s text item delimiters to " "
		set joinedArgs to quotedArgs as string
    set AppleScript'"'"'s text item delimiters to ""

		runCommandInteractively(joinedArgs)
end if
end run
'
echo "$osa"
osascript -e "$osa" -- "$@"
