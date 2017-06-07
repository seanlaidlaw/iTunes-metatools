display dialog "Sends metadata from current track in Spotify to selected track in iTunes" with icon note buttons {"Art", "All Tags", "Cancel"} default button "Art"




set x to button returned of result
if x is "Art" then
	
	--Download the artwork and save as a jpeg
	tell application "Spotify"
		set myURL to (artwork url of current track) as text
		set posixPath to POSIX path of (((path to me) as text) & "::")
		set aliasPath to (((((path to me) as text) & "::") as alias) as text) & "image.jpg"
		set cmd to "cd " & posixPath & "; curl " & myURL & " -o image.jpg"
		do shell script cmd
	end tell
	
	
	
	set Res to paragraphs of (do shell script "sips -g pixelHeight -g pixelWidth " & quoted form of POSIX path of aliasPath & " | grep pixel | cut -d':' -f 2 | cut -d ' ' -f 2")
	
	set artHeight to ((item 1 of Res) as integer)
	set artWidth to ((item 2 of Res) as integer)
	log "Spotify Res: " & artWidth & "x" & artHeight
	
	set my_action to ""
	if artWidth is not equal to 500 then
		set my_action to "resize"
	else if artHeight is not equal to 500 then
		set my_action to "resize"
	end if
	
	(*	
	if my_action is "resize" then
		--		set imgFile to aliasPath as alias

		log "Resizing Spotify artwork..."
		tell application "Image Events"
			launch
			
			set this_image to open imgFile
			scale this_image to size 500
			save this_image with icon
			close this_image
		end tell
	end if
			*)
	
	
	
	--Read the jpeg file into a variable as data
	set pathToImage to "Macintosh HD:Users:seanlaidlaw:Dropbox:Automation:Spotify:image.jpg"
	set currentArtwork to (read (file (pathToImage as text)) as data)
	
	--Set the artwork of all selected to that variable
	tell application "iTunes"
		repeat with myTrack in selection
			set data of artwork 1 of myTrack to currentArtwork
			log (name of myTrack) & " artwork modified"
		end repeat
	end tell
	log "Artwork Added."
	
	
else if x is "All Tags" then
	tell application "Spotify"
		set myArtist to artist of current track
		set myAlbum to album of current track
		set myAlbumArtist to album artist of current track
		set myDisc to disc number of current track
		set myTrack to track number of current track
		
		if myAlbumArtist is not equal to myArtist then
			set myArtist to myAlbumArtist
		end if
	end tell
	
	tell application "iTunes"
		set oldfi to fixed indexing
		set fixed indexing to true
		
		set currentTrack to first item of selection
		set artist of currentTrack to myArtist
		set album of currentTrack to myAlbum
		set disc number of currentTrack to myDisc
		set track number of currentTrack to myTrack
	end tell
	
	--Download the artwork and save as a jpeg
	tell application "Spotify"
		set myURL to (artwork url of current track) as text
		set posixPath to POSIX path of (((path to me) as text) & "::")
		set aliasPath to (((((path to me) as text) & "::") as alias) as text) & "image.jpg"
		set cmd to "cd " & posixPath & "; curl " & myURL & " -o image.jpg"
		do shell script cmd
	end tell
	
	--Read the jpeg file into a variable as data
	set pathToImage to "Macintosh HD:Users:seanlaidlaw:Dropbox:Automation:Spotify:image.jpg"
	set currentArtwork to (read file pathToImage as data)
	
	
	--Set itunes data to that variable
	tell application "iTunes"
		set data of artwork 1 of (currentTrack) to currentArtwork
		set fixed indexing to oldfi
	end tell
	
	log "All Tags Added."
end if

