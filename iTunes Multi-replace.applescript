#!/usr/bin/env osascript
--version 0.2

tell application "iTunes"
	set sel to selection
	repeat with origTrack in sel
		set origTrack_name to name of origTrack
		set origTrack_artist to artist of origTrack
		set origTrack_album to album of origTrack
		set origTrack_dbID to database ID of origTrack
		set origTrack_size to size of origTrack
		set origTrack_bit to bit rate of origTrack
		
		--set othertracks to (every track of library playlist 1 whose name is origTrack_name and artist is origTrack_artist and album is origTrack_album and database ID is not origTrack_dbID and size is not origTrack_size)
		
		set othertracks to (every track of library playlist 1 whose name is origTrack_name and artist is origTrack_artist and database ID is not origTrack_dbID and size is not origTrack_size)
		if (count of othertracks) > 0 then
			
			log ("File1: " & origTrack_name & " <++> " & origTrack_artist & " <++> " & origTrack_album & " <++> " & origTrack_bit & " kbps")
			
			repeat with othertracks_origTrack in othertracks
				set othertracks_name to name of othertracks_origTrack
				set othertracks_artist to artist of othertracks_origTrack
				set othertracks_album to album of othertracks_origTrack
				set othertracks_dbID to database ID of othertracks_origTrack
				set othertracks_size to size of othertracks_origTrack
				set othertracks_bit to bit rate of othertracks_origTrack
				
				if size of othertracks_origTrack is not equal to origTrack_size then
					if database ID of othertracks_origTrack is not equal to origTrack_dbID then
						log ("File2: " & othertracks_name & " <++> " & othertracks_artist & " <++> " & othertracks_album & " <++> " & othertracks_bit & " kbps")
						
						
						tell application "iTunes"
							
							--Define new track and old track as being oldest date added and newist date added respectively
							set select1 to origTrack
							set date1 to date added of select1
							set bit1 to bit rate of select1
							set select2 to othertracks_origTrack
							set date2 to date added of select2
							set bit2 to bit rate of select2
							
							if date added of select1 is less than date added of select2 then
								log "old track is " & bit1 & "kbps ; and new Track is " & bit2 & "kbps."
								set oldTrack to select1
								set newTrack to select2
								set HigherBit to "2"
							else
								log "old track is " & bit2 & "kbps ; and new Track is " & bit1 & "kbps."
								set oldTrack to select2
								set newTrack to select1
								set HigherBit to "1"
							end if
							
							
							if (name of select1) is not equal to (name of select2) then
								set question to display dialog "Names not identical, continue?" buttons {"Replace Anyway", "Cancel"} default button "Cancel"
								set answer to button returned of question
								
								if answer is "Cancel" then
									
									exit repeat
								end if
							end if
							
							
							--Gather Metadata
							set album artist of newTrack to ""
							-- set comment of newTrack to ""
							set album of newTrack to (album of oldTrack as text)
							set artist of newTrack to (artist of oldTrack as text)
							set name of newTrack to (name of oldTrack as text)
							set disc count of newTrack to (disc count of oldTrack as text)
							set disc number of newTrack to (disc number of oldTrack as text)
							set track count of newTrack to (track count of oldTrack as text)
							set track number of newTrack to (track number of oldTrack as text)
							set year of newTrack to (year of oldTrack as text)
							set rating of newTrack to (rating of oldTrack as text)
							set lyrics of newTrack to (lyrics of oldTrack as text)
							set genre of newTrack to (genre of oldTrack as text)
							set composer of newTrack to (composer of oldTrack as text)
							set comment of newTrack to (comment of oldTrack as text)
							set bpm of newTrack to (bpm of oldTrack as text)
							
							try
								set myPICTData to raw data of artwork 1 of oldTrack
								set data of artwork 1 of newTrack to myPICTData
							end try
							
							--Redo this as items will have changed with previous actions	
							--Define new track and old track as being oldest date added and newist date added respectively
							set select1 to origTrack
							set date1 to date added of select1
							set bit1 to bit rate of select1
							set select2 to othertracks_origTrack
							set date2 to date added of select2
							set bit2 to bit rate of select2
							
							if date added of select1 is less than date added of select2 then
								log "old track is " & bit1 & "kbps ; and new Track is " & bit2 & "kbps."
								set oldTrack to select1
								set newTrack to select2
								set HigherBit to "2"
							else
								log "old track is " & bit2 & "kbps ; and new Track is " & bit1 & "kbps."
								set oldTrack to select2
								set newTrack to select1
								set HigherBit to "1"
							end if
							
							
							
							
							set oldTrack_file to (location of oldTrack)
							log "old file is " & (oldTrack_file as string)
							set newTrack_file to (location of newTrack)
							log "new file is " & (newTrack_file as string)
							
							set oldTrack_dir to (do shell script "dirname " & quoted form of (POSIX path of oldTrack_file)) & "/"
							set oldTrack_dir to oldTrack_dir as Unicode text
							set oldTrack_dir_posix to oldTrack_dir
							set oldTrack_dir to (POSIX file oldTrack_dir) as alias
							
							set newTrack_dir to (do shell script "dirname " & quoted form of (POSIX path of newTrack_file)) & "/"
							set newTrack_dir to newTrack_dir as Unicode text
							set newTrack_dir to (POSIX file newTrack_dir) as alias
							
							
							tell application "Finder"
								
								set oldTrack_ext to (name extension of oldTrack_file)
								set newTrack_ext to (name extension of newTrack_file)
								
								
								set old_fileName to (name of oldTrack_file)
								set extensionLess to ((characters 1 thru -4 of old_fileName) as string)
								log "extensionLess : " & extensionLess
								
								set cmd to "mv " & quoted form of POSIX path of (oldTrack_file as text) & " ~/.Trash"
								--set cmd to "rm " & quoted form of POSIX path of (oldTrack_file as text)
								do shell script cmd
								set the name of file newTrack_file to old_fileName
								set newTrack_file to ((newTrack_dir as string) & (old_fileName as string))
								log "post-rename newTrack_file : " & (name of file newTrack_file)
								
								
								
								if oldTrack_dir is not newTrack_dir then
									log "old dir : " & oldTrack_dir & " |  new dir : " & newTrack_dir
									--try
									move file newTrack_file to oldTrack_dir
									
								end if
								
								
								if oldTrack_ext is equal to newTrack_ext then
									log "same extension"
									tell application "iTunes"
										play oldTrack
										delay 0.25
										pause oldTrack
									end tell
								else
									try
										tell application "iTunes"
											play oldTrack
											delay 0.25
											pause oldTrack
										end tell
									end try
									log "different  extension"
									log "extension should be : " & newTrack_ext & ", but is " & oldTrack_ext
									tell application "iTunes"
										try
											play oldTrack
											delay 0.25
											pause oldTrack
										end try
										
										--renaming file extension to match what the file with play with
										tell application "Finder"
											set neoTrackNameCut to (characters 1 thru -4 of (old_fileName))
											try
												set name of file newTrack_file to (neoTrackNameCut & newTrack_ext as text)
											on error
												
												
												set renameCmd to "cd \"" & oldTrack_dir_posix & "\"; mv \"" & neoTrackNameCut & oldTrack_ext & "\" \"" & neoTrackNameCut & newTrack_ext & "\""
												log "used shell cmd"
												
												display notification "used shell cmd"
												do shell script renameCmd
											end try
										end tell
										tell application "iTunes"
											play oldTrack
											delay 0.25
											pause oldTrack
										end tell
										--end try
									end tell
									
								end if
							end tell
							
							
							tell application "iTunes"
								--Define new track and old track as being higher and lower bitrate respectively
								if HigherBit is "2" then
									set newTrack to select2
								else
									set newTrack to select1
								end if
								set newTrackName to (name of newTrack as string)
								delete newTrack
								log "Deleted : " & newTrackName
							end tell
							
							
						end tell
						
						try
							tell application "iTunes"
								play oldTrack
								delay 0.25
								pause oldTrack
								set loved of oldTrack to true
							end tell
						end try
						
						
						
						
					end if
				end if
			end repeat
			
			
		end if
		
	end repeat
	
end tell