#!/usr/bin/env osascript

tell application "iTunes"
	set counter to 0
	set sel to selection
	repeat with myTrack in sel
		set mybitrate to bit rate of myTrack
		if mybitrate is greater than 361 then
			set counter to counter + 1
			
			-- Set file
			set mytrack_name to (name of myTrack)
			log (counter as string) & " - " & mytrack_name
			set mytrack_file to (location of myTrack)
			
			-- get and escape path for track file
			set mytrack_posix to (POSIX path of mytrack_file)
			set mytrack_posix to (my replace_chars(mytrack_posix, "$", "\\$"))
			
			-- convert the alac to wav
			set track_convert_cmd to "/usr/local/bin/ffmpeg -y -loglevel panic -i \"" & mytrack_posix & "\" \"" & mytrack_posix & ".wav\""
			set track_convert to do shell script track_convert_cmd
			
			-- test the wav for lossless-ness
			set track_test_cmd to "/usr/local/bin/lac \"" & mytrack_posix & ".wav\" | grep \"Result: \""
			set track_test to do shell script track_test_cmd
			if (track_test as string) is not equal to "Result: Clean" then
				try
					duplicate myTrack to user playlist "Not-Lossless"
				on error
					make new user playlist with properties {name:"Not-Lossless"}
					duplicate myTrack to user playlist "Not-Lossless"
				end try
				log (mytrack_name as string) & " : " & track_test
			end if
			
			do shell script "rm \"" & mytrack_posix & ".wav\""
		end if
	end repeat
end tell

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars