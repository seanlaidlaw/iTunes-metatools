--Make Temp Folder
try
	set tempFolder to ((((path to me) as text) & "::TempFolder") as alias)
on error
	set posixTemp to (POSIX path of (((path to me) as text) & "::"))
	set cmd to "cd '" & posixTemp & "' ;" & " mkdir TempFolder"
	do shell script cmd
	set tempFolder to ((((path to me) as text) & "::TempFolder") as alias)
end try



--Script
tell application "iTunes"
	
	repeat with currentTrack in selection
		
		
		--	set currentTrack to first item of selection
		set trackName to name of currentTrack
		set trackArtist to artist of currentTrack
		set artworkCount to count of artwork of currentTrack
		if artworkCount > 0 then
			tell application "iTunes" to tell artwork 1 of currentTrack
				try
					set srcBytes to raw data
				on error
					duplicate currentTrack to user playlist "ImproperArt"
					log "...to replace artwork"
					exit repeat
				end try
				-- figure out the proper file extension
				if format is Çclass PNG È then
					set ext to ".png"
				else
					set ext to ".jpg"
				end if
			end tell
			
			
			--Save artowrk as image
			set imgName to ((tempFolder as text) & "artwork" & ext)
			try
				set imgFile to open for access file imgName with write permission
			on error number -49
				log "file already open"
				set imgFile to (imgName as alias)
			end try
			
			set eof imgFile to 0
			write srcBytes to imgFile
			
			
			set Res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of imgName & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
			
			set artHeight to ((item 1 of Res) as integer)
			set artWidth to ((item 2 of Res) as integer)
			log "Old Res: " & artWidth & "x" & artHeight & "  |  " & trackName & " - " & trackArtist
			
			close access imgFile
			
			set imgFile to ((tempFolder as text) & "artwork" & ext) as alias
			
			
			set theArt to ""
			
			if artHeight > 500 then
				set theArt to "resize"
			else if artWidth > 500 then
				set theArt to "resize"
			end if
			
			if artHeight < 500 then
				set theArt to "replace"
			else if artWidth < 500 then
				set theArt to "replace"
			end if
			
			
			if artHeight is equal to 500 and artWidth is equal to 500 then set theArt to "skip"
			
			
			
			if theArt is "resize" then
				log ".. Resizing"
				tell application "Finder"
					tell application "Image Events"
						launch
						set this_image to open imgFile
						scale this_image to size 500
						save this_image with icon
						close this_image
					end tell
				end tell
				
				set Res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of imgName & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
				
				set artHeight to item 1 of Res
				set artWidth to item 2 of Res
				log "...New Res: " & artWidth & "x" & artHeight
				
				
				set myArt to (read file (imgName) as picture)
				set data of artwork 1 of currentTrack to myArt
				
				
				
			else if theArt is "replace" then
				duplicate currentTrack to user playlist "ImproperArt"
				log ".. To be replaced"
			end if
			
			
			
			
			
			
			try
				set cmd to "cd '" & (POSIX path of tempFolder) & "' ;" & " rm artwork" & ext
				do shell script cmd
			end try
			
		end if
	end repeat
end tell


--Delete Temp Folder

