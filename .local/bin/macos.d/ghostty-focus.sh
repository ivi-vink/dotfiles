#!/bin/bash
include='
on listWindows(appName)
tell application "System Events"
	if exists (processes where name is appName) then
		tell process appName
			set windowTitles to {}
			repeat with w in windows
				set end of windowTitles to name of w
			end repeat
			set AppleScript'"'"'s text item delimiters to linefeed
			return windowTitles
		end tell
	else
		error "A grievous condition hath occurred." number 1
	end if
end tell
end listWindows

on focusWindow(appName, args)
  -- Replace this with your desired client identifier
  set sessionId to item 1 of args
  set clientId to item 2 of args
  set clientTitle to (clientId & "@[" & sessionId & "]")
  tell application "System Events"
  	if exists (processes where name is appName) then
  		tell process appName
  			repeat with w in windows
  				set winName to name of w
  				if winName contains clientTitle and winName contains "Kakoune" then
  					-- Bring Ghostty to the front
  					tell application appName to activate

  					-- Set focus to the matching window
  					set frontmost to true
  					set value of attribute "AXMain" of w to true

  					return "Activated window: " & winName
  				end if
  			end repeat
  			return "No matching window found."
  		end tell
  	else
  		return "Ghostty is not running."
  	end if
  end tell
end focusWindow
'

listwindows() {
  osascript -e "$include"'
on run args
if class of args is list then -- arguments passed come in as a list
    set result to listWindows(item 1 of args)
		set AppleScript'"'"'s text item delimiters to linefeed
		return result as string
end if
end run
' -- "$@"
}
focuswindow() {
  osascript -e "$include"'
on run args
if class of args is list then -- arguments passed come in as a list
		set result to focusWindow("Ghostty", args)
		set AppleScript'"'"'s text item delimiters to linefeed
		return result as string
end if
end run
' -- "$@"
}
# listwindows "Ghostty"
# echo "$KAKOUNE_CLIENT@[$KAKOUNE_SESSION]"
focuswindow "$@"
