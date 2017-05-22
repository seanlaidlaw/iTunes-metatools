tell application "iTunes"
	
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
	
	
	
	--Gather Metadata
	set album artist of oldTrack to " "
	set comment of oldTrack to " "
	set name of oldTrack to (name of newTrack as text)
	set album of oldTrack to (album of newTrack as text)
	set artist of oldTrack to (artist of newTrack as text)
	set name of oldTrack to (name of newTrack as text)
	set disc count of oldTrack to (disc count of newTrack as text)
	set disc number of oldTrack to (disc number of newTrack as text)
	set track count of oldTrack to (track count of newTrack as text)
	set track number of oldTrack to (track number of newTrack as text)
	set year of oldTrack to (year of newTrack as text)
	set lyrics of oldTrack to (lyrics of newTrack as text)
	set genre of oldTrack to (genre of newTrack as text)
	set composer of oldTrack to (composer of newTrack as text)
	
	
	try
		set myPICTData to raw data of artwork 1 of newTrack
		set data of artwork 1 of oldTrack to myPICTData
	end try
end tell
log "Finished"
