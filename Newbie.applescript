#!/usr/bin/env osascript
--version 1.0

(* Options to change behavior of script *)

--if below is "true", the script will remove data from composer & album artist tags from non-classical music
set minimalMetadata to true

--if below is "true", the script will resize artwork of album of selected tracks to be no more than 640x640
set resizeArtwork to true
--if the above option is true then set the below to the requested resolution (by default its 640x640)
set resizeSize to 640

(* Start of script *)

tell application "iTunes"
	repeat with trk in selection
		set masterArtist to artist of trk
		set artistSongs to (every track of library playlist 1 whose artist is masterArtist)
		
		set masterGenre to ""
		repeat with trk in artistSongs
			log name of trk as string
			if (genre of trk) is not equal to "" then
				set masterGenre to genre of trk
				set masterArtist_track to trk
				exit repeat
			end if
		end repeat
		
		repeat with trk in artistSongs
			if (genre of trk) is not equal to "" then
				if date added of trk is less than date added of masterArtist_track then
					set masterGenre to genre of trk
					set masterArtist_track to trk
				end if
			end if
		end repeat
		if masterGenre is equal to "" then exit repeat
		log "Artist Genre : " & masterGenre & " | from : " & (name of masterArtist_track as string)
		
		repeat with trk in artistSongs
			if (genre of trk) is not equal to masterGenre then
				set genre of trk to masterGenre
				log "Genre of " & (name of trk as string) & " changed to " & masterGenre
			end if
		end repeat
		
	end repeat
end tell

tell application "iTunes"
	set albumsWithDups to {}
	repeat with trk in selection
		if album of trk is not "" then
			set inputdups to (my encode_text(((artist of trk as string)), true, true) & "@" & (my encode_text((album of trk as string), true, true)))
			set albumsWithDups to albumsWithDups & inputdups
		end if
	end repeat
end tell

set albumsNames to my removeDuplicates(albumsWithDups)

-- Check each album
repeat with currentAlbum in albumsNames
	try
		set tempFolder to ((((path to me) as text) & "::TempFolder") as alias)
	on error
		set posixTemp to (quoted form of POSIX path of (((path to me) as text) & "::"))
		set cmd to "cd '" & posixTemp & "' ;" & " mkdir TempFolder"
		do shell script cmd
		set tempFolder to ((((path to me) as text) & "::TempFolder") as alias)
	end try
	
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {"@"}
	set masterArtist to (first text item of currentAlbum) as text
	set myAlbum to (second text item of currentAlbum) as text
	set AppleScript's text item delimiters to oldDelims
	set masterArtist to decode_text(masterArtist)
	set myAlbum to decode_text(myAlbum)
	log masterArtist & "_" & myAlbum & "_START"
	
	
	tell application "iTunes"
		set albumSongs to (every track of library playlist 1 whose album is myAlbum and artist is masterArtist)
		
		set masterDiscc to 0
		repeat with trk in albumSongs
			if (disc count of trk) is greater than 0 then
				set masterDiscc to disc count of trk
				exit repeat
			end if
		end repeat
		
		set masterTrackc to 0
		repeat with trk in albumSongs
			if (track count of trk) is greater than 0 then
				set masterTrackc to track count of trk
				exit repeat
			end if
		end repeat
		
		set masterYear to 0
		repeat with trk in albumSongs
			if (year of trk) is greater than 0 then
				set masterYear to year of trk
				exit repeat
			end if
		end repeat
		
		set masterArt_track to ""
		repeat with trk in albumSongs
			if (count of artwork of trk) is greater than 0 then
				set masterArt_track to trk
				set masterArt_track_date to (date added of masterArt_track)
				exit repeat
			end if
		end repeat
		
		repeat with album_trk in albumSongs
			log (name of album_trk as string)
			if (count of artwork of album_trk) is greater than 0 then
				--imported all at once can give tracks the same date added which confuses script
				
				if (date added of album_trk) < masterArt_track_date then
					set masterArt_track to album_trk
				end if
				
				set dateadded to ""
				repeat with para in paragraphs of (comment of album_trk as text)
					if para starts with "Date Added:" then
						set dateadded to para
			end if
		end repeat
		
				if dateadded is not "" then
					set dateadded to ((characters 13 thru -1 of dateadded) as string)
					set dateadded to (my replace_chars(dateadded, "Z", ""))
					set dateadded to (my replace_chars(dateadded, "T", " "))
					set dateadded to my dateObject(dateadded)
					if dateadded < masterArt_track_date then
						set masterArt_track to album_trk
						set masterArt_track_date to dateadded
					end if
				end if
			end if
			
		end repeat
		
		
		
		
		if (count of artwork of masterArt_track) is less than 1 then
			log "No artwork to apply"
			exit repeat
		end if
		
		
		log "Master: " & (name of masterArt_track as string)
		
		--Set masterArt_track album artwork
		tell application "iTunes" to tell artwork 1 of masterArt_track
			set srcBytes to raw data
			-- figure out the proper file extension
			try
				if format is class PNG then
					set ext to ".png"
				else
					set ext to ".jpg"
				end if
			on error
				set ext to ".jpg"
			end try
		end tell
		
		set masterImg_name to ((tempFolder as text) & "master" & ext)
		set masterImg_file to open for access file masterImg_name with write permission
		
		set eof masterImg_file to 0
		write srcBytes to masterImg_file
		close access masterImg_file
		
		if resizeArtwork then
			set res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of masterImg_name & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
			set artHeight to item 1 of res
			set artWidth to item 2 of res
			log "...Old Res: " & artWidth & "x" & artHeight
			
			set resizeImage to false
			if (artWidth as integer) > resizeSize then
				set resizeImage to true
			end if
			if (artHeight as integer) > resizeSize then
				set resizeImage to true
			end if
			
			if resizeImage is true then
				tell application "Finder"
					tell application "Image Events"
						launch
						set masterImg to open masterImg_name
						scale masterImg to size resizeSize
						save masterImg with icon
						close masterImg
					end tell
				end tell
				
				set res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of masterImg_name & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
				
				set artHeight to item 1 of res
				set artWidth to item 2 of res
				log "...New Res: " & artWidth & "x" & artHeight
			else
				log "Not Resizing : image already at ideal size"
			end if
			
		end if
		
		set masterHash to do shell script ("md5 " & quoted form of POSIX path of tempFolder & "master" & ext & " | grep -o \"................................$\"")
		log "Master: " & masterHash
		
		
		--Add tags from master to individual tracks 
		repeat with trk in albumSongs
			if media kind of trk is song and compilation of trk is not true and album of trk is not "" then
				try
					set tempFolder to ((((path to me) as text) & "::TempFolder") as alias)
				on error
					set posixTemp to (quoted form of POSIX path of (((path to me) as text) & "::"))
					set cmd to "cd '" & posixTemp & "' ;" & " mkdir TempFolder"
					do shell script cmd
					set tempFolder to ((((path to me) as text) & "::TempFolder") as alias)
				end try
				
				if masterDiscc is not 0 then set disc count of trk to masterDiscc
				if masterTrackc is not 0 then set track count of trk to masterTrackc
				if masterTrackc is not 0 then set year of trk to masterYear
				
				if (count of artwork of trk) is not greater than 0 then
					set masterImg_read to (read file (masterImg_name) as picture)
					try
						set data of artwork 1 of trk to masterImg_read
					on error
						log "error setting artwork of " & (name of trk)
						try
							duplicate trk to user playlist "Artwork to Replace"
						on error
							make new user playlist with properties {name:"Artwork to Replace"}
							duplicate trk to user playlist "Artwork to Replace"
						end try
					end try
				else
					tell application "iTunes" to tell artwork 1 of trk
						set srcBytes to raw data
						-- figure out the proper file extension
						try
							if format is class PNG then
								set ext to ".png"
							else
								set ext to ".jpg"
							end if
						on error
							set ext to ".jpg"
						end try
					end tell
					
					
					--Save artowrk as image
					tell application "Finder"
						set imgName to ((tempFolder as text) & "artwork" & ext)
						log imgName
						try
							set imgFile to open for access file imgName with write permission
						on error number -49
							--log "file already open"
							set imgFile to (imgName as alias)
						end try
						
						set eof imgFile to 0
						write srcBytes to imgFile
						close access imgFile
					end tell
					set imgHash to do shell script ("md5 " & quoted form of POSIX path of tempFolder & "artwork" & ext & " | grep -o \"................................$\"")
					
					
					
					if (imgHash as text) is equal to (masterHash as text) then
						log "same hash - " & (name of trk as text)
						
					else
						log "DIFF_" & (name of trk) & ": " & imgHash
						set masterImg_read to (read file (masterImg_name) as picture)
						try
							set data of artwork 1 of trk to masterImg_read
						on error
							log "error setting artwork of " & (name of trk)
							try
								duplicate trk to user playlist "Artwork to Replace"
							on error
								make new user playlist with properties {name:"Artwork to Replace"}
								duplicate trk to user playlist "Artwork to Replace"
							end try
						end try
					end if
					
					set cmd to "rm -rf " & quoted form of POSIX path of tempFolder
					--	do shell script cmd
				end if
			end if
		end repeat
	end tell
end repeat

if minimalMetadata is true then
	tell application "iTunes"
		repeat with trk in selection
			if compilation of trk is false then
				if genre of trk is not in {"Classical", "Soundtrack"} then
					if album artist of trk is not equal to "" then
						log "AA: " & (album artist of trk)
						set album artist of trk to ""
						log "AA: " & (album artist of trk)
					end if
					if composer of trk is not equal to "" then
						log "Composer: " & (composer of trk)
						set composer of trk to ""
						log "Composer: " & (composer of trk)
					end if
					if lyrics of trk is not equal to "" then
						log "Lyrics: " & (lyrics of trk)
						set lyrics of trk to ""
						log "Lyrics: " & (lyrics of trk)
					end if
				end if
			end if
			
			
			set myComment to (comment of trk as text)
			
			set dateadded to ""
			set ivolumeadjust to ""
			repeat with para in paragraphs of myComment
				if para starts with "Date Added:" then
					set dateadded to para
				end if
				if para starts with "Adjusted by iVolume" then
					set ivolumeadjust to para
				end if
			end repeat
			
			
			if dateadded is equal to "" then
				set dateadded to (date added of trk) as date
				tell application "Finder"
					set mymonth to (month of dateadded as integer)
					if mymonth is less than 10 then set mymonth to "0" & (mymonth as string)
					set myday to (day of dateadded as integer)
					if myday is less than 10 then set myday to "0" & (myday as string)
					set myhour to (hours of dateadded as integer)
					if myhour is less than 10 then set myhour to "0" & (myhour as string)
					set mymins to (minutes of dateadded as integer)
					if mymins is less than 10 then set mymins to "0" & (mymins as string)
					set mysecs to (seconds of dateadded as integer)
					if mysecs is less than 10 then set mysecs to "0" & (mysecs as string)
					
					set shortdate to (((year of dateadded as integer) as string) & "-" & mymonth & "-" & myday & "T" & myhour & ":" & mymins & ":" & mysecs & "Z")
					set dateadded to ("Date Added: " & shortdate as string) as string
				end tell
			end if
			
			
			if ivolumeadjust is not equal to "" then
				set newcomment to (dateadded & return & ivolumeadjust) as string
			else
				set newcomment to dateadded as string
			end if
			
			log newcomment
			if comment of trk is equal to newcomment then
				log "no change needed"
			else if comment of trk is equal to "" then
				log "adding comment : " & newcomment
			else
				log "changing comment : '" & (comment of trk as string) & "' to '" & newcomment & "'"
			end if
			
			set comment of trk to newcomment
			
			
			
			
			--if track name contains "feat" then make the F lowercase
			if name of trk contains "feat." then
				set newname to name of trk
				set newname to my replace_chars(newname, "Feat.", "feat.")
				set name of trk to newname
			end if
			
			
			--if track name begins with a space then remove the space
			if name of trk begins with " " then
				set newname to name of trk
				repeat while newname begins with " "
					set newname to ((characters 2 thru -1 of newname) as string)
				end repeat
				set name of trk to newname
			end if
			
			--if track name contains "  " then replace with " "
			if name of trk contains "  " then
				set newname to name of trk
				repeat while newname contains "  "
					set newname to my replace_chars(newname, "  ", " ")
				end repeat
				set name of trk to newname
			end if
			
		end repeat
	end tell
end if




--SUBROUTINES
on write_to_file(this_data, target_file, append_data) -- (string, file path as string, boolean)
	try
		set the target_file to the target_file as text
		set the open_target_file to open for access file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
		write this_data to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error
		try
			close access file target_file
		end try
		return false
	end try
end write_to_file

on dateObject(theDateString)
	set myDate to current date
	set {oti, text item delimiters} to {text item delimiters, " "}
	set {dateString, timeString} to text items of theDateString
	set text item delimiters to ":"
	set {hrs, mins, scs} to text items of timeString
	
	set hrsMins to hrs * hours + mins * minutes + scs
	
	set {yr, Mnth, dy} to words of dateString
	
	set the time of myDate to hrsMins
	set the year of myDate to yr
	set the month of myDate to Mnth
	set the day of myDate to dy
	
	set text item delimiters to oti
	return myDate
end dateObject


on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

to parseCsvEntry(csvEntry)
	set AppleScript's text item delimiters to ","
	set {theArtist, theGenre} to csvEntry's text items
	set AppleScript's text item delimiters to {""}
	return {theArtist, theGenre}
end parseCsvEntry

on encode_text(this_text, encode_URL_A, encode_URL_B)
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789"
	set the URL_A_chars to "$+!'/?;&@=#%><{}[]\"~`^\\|*"
	set the URL_B_chars to ".-_:"
	set the acceptable_characters to the standard_characters
	if encode_URL_A is false then set the acceptable_characters to the acceptable_characters & the URL_A_chars
	if encode_URL_B is false then set the acceptable_characters to the acceptable_characters & the URL_B_chars
	set the encoded_text to ""
	repeat with this_char in this_text
		if this_char is in the acceptable_characters then
			set the encoded_text to (the encoded_text & this_char)
		else
			set the encoded_text to (the encoded_text & encode_char(this_char)) as string
		end if
	end repeat
	return the encoded_text
end encode_text

on encode_char(this_char)
	set the ASCII_num to (the ASCII number this_char)
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set x to item ((ASCII_num div 16) + 1) of the hex_list
	set y to item ((ASCII_num mod 16) + 1) of the hex_list
	return ("%" & x & y) as string
end encode_char

on decode_text(this_text)
	set flag_A to false
	set flag_B to false
	set temp_char to ""
	set the character_list to {}
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "%" then
			set flag_A to true
		else if flag_A is true then
			set the temp_char to this_char
			set flag_A to false
			set flag_B to true
		else if flag_B is true then
			set the end of the character_list to my decode_chars(("%" & temp_char & this_char) as string)
			set the temp_char to ""
			set flag_A to false
			set flag_B to false
		else
			set the end of the character_list to this_char
		end if
	end repeat
	return the character_list as string
end decode_text

on decode_chars(these_chars)
	copy these_chars to {indentifying_char, multiplier_char, remainder_char}
	set the hex_list to "123456789ABCDEF"
	if the multiplier_char is in "ABCDEF" then
		set the multiplier_amt to the offset of the multiplier_char in the hex_list
	else
		set the multiplier_amt to the multiplier_char as integer
	end if
	if the remainder_char is in "ABCDEF" then
		set the remainder_amt to the offset of the remainder_char in the hex_list
	else
		set the remainder_amt to the remainder_char as integer
	end if
	set the ASCII_num to (multiplier_amt * 16) + remainder_amt
	return (ASCII character ASCII_num)
end decode_chars

on removeDuplicates(lst)
	-- from http://applescript.bratis-lover.net/library/list/#removeDuplicates
	local lst, itemRef, res, itm
	try
		if lst's class is not list then error "not a list." number -1704
		script k
			property l : lst
			property res : {}
		end script
		repeat with itemRef in k's l
			set itm to itemRef's contents
			-- note: minor speed optimisation when removing duplicates 
			-- from ordered lists: assemble new list in reverse so 
			-- 'contains' operator checks most recent item first
			if k's res does not contain {itm} then set k's res's beginning to itm
			
		end repeat
		return k's res's reverse
	on error eMsg number eNum
		error "Can't removeDuplicates: " & eMsg number eNum
	end try
end removeDuplicates
