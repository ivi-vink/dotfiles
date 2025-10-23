#!/bin/bash


osa='
on runCommandInteractively(theCommand)
	tell application "Ghostty" to activate

  tell application "System Events"
    tell process "Ghostty"
      keystroke return using command down
    end tell
  end tell
  delay 0.2

	tell application "System Events"
		keystroke ((" " & theCommand) as text)
		keystroke return
	end tell
end runCommandInteractively

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
osascript -e "$osa" -- "$@"
