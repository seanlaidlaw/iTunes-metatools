#!/usr/bin/env osascript
--version 0.8

set keepHigherBitrateTrackMetadata to false

-- This script usually determines old and new track based on bitrate (lower bitrate being older track)
-- making this "true" however will override that and make it determine whats old and new based on the date added metadata
set UseDateAddedInstead to true

tell application "iTunes"
	
	if not UseDateAddedInstead then
		--Define new track and old track as being higher and lower bitrate respectively
		set select1 to first item in selection
		set bit1 to bit rate of select1
		set select2 to second item in selection
		set bit2 to bit rate of select2
		
		if bit1 is less than bit2 then
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
		
	else if UseDateAddedInstead then
		--Define new track and old track as being oldest date added and newist date added respectively
		set select1 to first item in selection
		set date1 to date added of select1
		set bit1 to bit rate of select1
		set select2 to second item in selection
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
		
	end if
	
	
	
	if not keepHigherBitrateTrackMetadata then
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
		set bpm of newTrack to (bpm of oldTrack as text)
		
		try
			set myPICTData to raw data of artwork 1 of oldTrack
			set data of artwork 1 of newTrack to myPICTData
		end try
	end if
	
	--Redo this as items will have changed with previous actions
	if not UseDateAddedInstead then
		--Define new track and old track as being higher and lower bitrate respectively
		set select1 to first item in selection
		set bit1 to bit rate of select1
		set select2 to second item in selection
		set bit2 to bit rate of select2
		
		if bit1 is less than bit2 then
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
		
	else if UseDateAddedInstead then
		--Define new track and old track as being oldest date added and newist date added respectively
		set select1 to first item in selection
		set date1 to date added of select1
		set bit1 to bit rate of select1
		set select2 to second item in selection
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
		
	end if
	
	
	
	set oldTrack_file to (location of oldTrack)
	log "old file is " & (oldTrack_file as string)
	set newTrack_file to (location of newTrack)
	log "new file is " & (newTrack_file as string)
	
	set oldTrack_dir to (do shell script "dirname " & quoted form of (POSIX path of oldTrack_file)) & "/"
	set oldTrack_dir to oldTrack_dir as Unicode text
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
					set name of file newTrack_file to (neoTrackNameCut & newTrack_ext as text)
					log "renamed name : " & (name of file newTrack_file)
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
	end tell
end try

log "Finished"