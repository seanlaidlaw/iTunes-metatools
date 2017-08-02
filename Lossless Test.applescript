#!/bin/bash

# for ALAC
for alacfile in *.m4a; do 
    ffmpeg -y -loglevel panic -i "$alacfile" "$alacfile".wav
        echo "File: $alacfile"
    ffmpeg -y -loglevel panic -i "$alacfile" "$alacfile".wav
    mylac=$(lac "$alacfile".wav | grep "Result: Clean")
    rm "$alacfile".wav

    if [[ "$mylac" == "Result: Clean" ]] ; then
        echo "   >> $alacfile : Clean"
    else
        echo "   >> $alacfile : NOT Clean !!"
        mv "$alacfile" "uncleanFLAC"
    fi
done

# for FLAC
for flacfile in *.flac; do 
    echo "File: $flacfile"
    ffmpeg -y -loglevel panic -i "$flacfile" "$flacfile".wav
    mylac=$(lac "$flacfile".wav | grep "Result: Clean")
    rm "$flacfile".wav

    if [[ "$mylac" == "Result: Clean" ]] ; then
        echo "   >> $flacfile : Clean"
    else
        echo "   >> $flacfile : NOT Clean !!"
        mv "$alacfile" "uncleanFLAC"
    fi
done