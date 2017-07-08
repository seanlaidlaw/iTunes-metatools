#!/usr/bin/env osascript

(* Options to change behavior of script *)

--if below is "true", the script will remove data from composer & album artist tags from non-classical music
set minimalmetadata to true

--if below is "true", the script will resize artwork of album of selected tracks to be no more than 500x500
set resizeartwork to true
--if the above option is true then set the below to the requested resolution (by default its 500x500)
set resizeWidth to 500
set resizeHeight to 500

(* Start of script *)

tell application "iTunes"
	repeat with myTrack in selection
		set myartist to artist of myTrack
		set artistSongs to (every track of library playlist 1 whose artist is myartist)
		
		set masterGenre to ""
		repeat with trk in artistSongs
			log name of trk as string
			if (genre of trk) is not equal to "" then
				set masterGenre to genre of trk
				set masterartisttrack to trk
				exit repeat
			end if
		end repeat
		
		repeat with trk in artistSongs
			if (genre of trk) is not equal to "" then
				if date added of trk is less than date added of masterartisttrack then
					set masterGenre to genre of trk
					set masterartisttrack to trk
				end if
			end if
		end repeat
		if masterGenre is equal to "" then exit repeat
		log "Artist Genre : " & masterGenre & " | from : " & (name of masterartisttrack as string)
		
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
	repeat with myTrack in selection
		if album of myTrack is not "" then
			set inputdups to (my encode_text(((artist of myTrack as string)), true, true) & "@" & (my encode_text((album of myTrack as string), true, true)))
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
	set myartist to (first text item of currentAlbum) as text
	set myalbum to (second text item of currentAlbum) as text
	set AppleScript's text item delimiters to oldDelims
	set myartist to decode_text(myartist)
	set myalbum to decode_text(myalbum)
	log myartist & "_" & myalbum & "_START"
	
	
	tell application "iTunes"
		set albumSongs to (every track of library playlist 1 whose album is myalbum and artist is myartist)
		
		set masterdiscc to 0
		repeat with trk in albumSongs
			if (disc count of trk) is greater than 0 then
				set masterdiscc to disc count of trk
				exit repeat
			end if
		end repeat
		
		set masterarttrackc to 0
		repeat with trk in albumSongs
			if (track count of trk) is greater than 0 then
				set masterarttrackc to track count of trk
				exit repeat
			end if
		end repeat
		
		set masterartyear to 0
		repeat with trk in albumSongs
			if (year of trk) is greater than 0 then
				set masterartyear to year of trk
				exit repeat
			end if
		end repeat
		
		repeat with trk in albumSongs
			if (count of artwork of trk) is greater than 0 then
				set masterarttrack to trk
				exit repeat
			end if
		end repeat
		
		repeat with trk in albumSongs
			log (name of trk as string)
			if (count of artwork of trk) is greater than 0 then
				if date added of trk is less than date added of masterarttrack then
					set masterarttrack to trk
				end if
			end if
		end repeat
		
		if (count of artwork of masterarttrack) is less than 1 then
			log "No artwork to apply"
			exit repeat
		end if
		
		log "Master: " & (name of masterarttrack as string)
		
		--Set masterarttrack album artwork
		tell application "iTunes" to tell artwork 1 of masterarttrack
			set srcBytes to raw data
			-- figure out the proper file extension
			try
				if format is Çclass PNG È then
					set ext to ".png"
				else
					set ext to ".jpg"
				end if
			on error
				set ext to ".jpg"
			end try
		end tell
		
		set masterimgName to ((tempFolder as text) & "master" & ext)
		set masterimgFile to open for access file masterimgName with write permission
		
		set eof masterimgFile to 0
		write srcBytes to masterimgFile
		close access masterimgFile
		
		if resizeartwork is true then
			set res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of masterimgName & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
			set artHeight to item 1 of res
			set artWidth to item 2 of res
			log "...Old Res: " & artWidth & "x" & artHeight
			
			set resizeImage to false
			if artWidth > resizeWidth then
				set resizeImage to true
			end if
			if artHeight > resizeHeight then
				set resizeImage to true
			end if
			
			if resizeImage is true then
				tell application "Finder"
					tell application "Image Events"
						launch
						set this_image to open masterimgName
						scale this_image to size 500
						save this_image with icon
						close this_image
					end tell
				end tell
				
				set res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of masterimgName & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
				
				set artHeight to item 1 of res
				set artWidth to item 2 of res
				log "...New Res: " & artWidth & "x" & artHeight
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
				
				if masterdiscc is not 0 then set disc count of trk to masterdiscc
				if masterarttrackc is not 0 then set track count of trk to masterarttrackc
				if masterarttrackc is not 0 then set year of trk to masterartyear
				
				if (count of artwork of trk) is not greater than 0 then
					set myArt to (read file (masterimgName) as picture)
					try
						set data of artwork 1 of trk to myArt
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
					tell application "iTunes" to tell artwork 1 of masterarttrack
						set srcBytes to raw data
						-- figure out the proper file extension
						try
							if format is Çclass PNG È then
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
					set myHash to do shell script ("md5 " & quoted form of POSIX path of tempFolder & "artwork" & ext & " | grep -o \"................................$\"")
					
					
					
					if (myHash as text) is equal to (masterHash as text) then
						log "same hash - " & (name of trk as text)
						
					else
						log "DIFF_" & (name of trk) & ": " & myHash
						set myArt to (read file (masterimgName) as picture)
						try
							set data of artwork 1 of trk to myArt
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

if minimalmetadata is true then
	tell application "iTunes"
		repeat with myTrack in selection
			if genre of myTrack is not "Classical" then
				if album artist of myTrack is not equal to "" then
					log "AA: " & (album artist of myTrack)
					set album artist of myTrack to ""
					log "AA: " & (album artist of myTrack)
				end if
				if composer of myTrack is not equal to "" then
					log "Composer: " & (composer of myTrack)
					set composer of myTrack to ""
					log "Composer: " & (composer of myTrack)
				end if
			end if
			
			set myComment to (comment of myTrack as text)
			if myComment is not equal to "" then
				if (count paragraphs of myComment) is greater than 1 then
					set ASTID to AppleScript's text item delimiters
					set AppleScript's text item delimiters to {linefeed}
					set first_comment to first text item of myComment
					set second_comment to second text item of myComment
					set AppleScript's text item delimiters to ASTID
					
					if second_comment is not equal to "" then
						set comment of myTrack to first_comment
					end if
					
				else
					log "Para: " & (count paragraphs of myComment)
				end if
			end if
		end repeat
	end tell
end if




--SUBROUTINES

on write_to_file(this_data, target_file, append_data) -- (string, file path as string, boolean)
	try
		set the target_file to the target_file as text
		set the open_target_file to Â
			open for access file target_file with write permission
		if append_data is false then Â
			set eof of the open_target_file to 0
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
			if k's res does not contain {itm} then Â
				set k's res's beginning to itm
		end repeat
		return k's res's reverse
	on error eMsg number eNum
		error "Can't removeDuplicates: " & eMsg number eNum
	end try
end removeDuplicates
