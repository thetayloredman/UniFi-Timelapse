#!/bin/bash

#SNAP_BASE="/mnt/hgfs/Disk2/UniFi-Snaps"
SNAP_BASE="/nas/data/Development/UniFi/TimeLapse/UniFi-Timelapse/UniFi-Snaps"
OUT_DIR="$SNAP_BASE/timelapse"
DATE_EXT=`date '+%F %H:%M'`

declare -A CAMS

CAMS["Front Door"]="http://192.1.1.1/snap.jpeg"
CAMS["Back Door"]="http://192.1.1.2/snap.jpeg"
CAMS["Driveway"]="http://192.1.1.3/snap.jpeg"
CAMS["Back Garden"]="http://192.1.1.4/snap.jpeg"

# If we are in a terminal, be verbose.
if [[ -z $VERBOSE && -t 1 ]]; then
  VERBOSE=1
fi

log()
{
  if [ ! -z $VERBOSE ]; then echo "$@"; fi
}

logerr() 
{ 
  echo "$@" 1>&2; 
}

createDir()
{
  if [ ! -d "$1" ]; then
    mkdir "$1"
    # check error here
  fi  
}

getSnap() {

  snapDir="$SNAP_BASE/$1"
  if [ ! -d "$snapDir" ]; then
    mkdir -p "$snapDir"
    # check error here
  fi
  
  snapFile="$snapDir/$1 - $DATE_EXT.jpg"

  log savingSnap "$2" to "$snapFile" 

  wget --quiet -O "$snapFile" "$2"
}

createMovie()
{
  snapDir="$SNAP_BASE/$1"
  
  if [ ! -d "$snapDir" ]; then
    logerr "Error : No media files in '$snapDir'"
    exit 2
  fi

  createDir "$OUT_DIR"
  outfile="$OUT_DIR/$1 - $DATE_EXT.mp4"

  if [ "$2" = "today" ]; then
    log "Creating video of $1 from today's images"
    ffmpeg -r 15 -start_number 1 -pattern_type glob -i "$snapDir/"'*'"$(date '+%F')"'*.jpg' -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  elif [ "$2" = "yesterday" ]; then
    log "Creating video of $1 from yesterday's images"
    ffmpeg -r 15 -start_number 1 -pattern_type glob -i "$snapDir/"'*'"$(date '+%F' -d "1 day ago")"'*.jpg' -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  elif [ "$2" = "file" ]; then
    if [ ! -f "$3" ]; then
      logerr "ERROR file '$3' not found"
      exit 1
    fi
    log "Creating video of $1 from images in $3"
    ffmpeg -r 15 -start_number 1 -i "$(cat "$3")" -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  else
    log "Creating video of $1 from all images"
    ffmpeg -r 15 -start_number 1 -pattern_type glob -i "$snapDir/"'*.jpg' -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  fi

  # need to chance current dir so links work over network mounts
  cwd=`pwd`

  log "Created $outfile"

  cd "$cwd"
}

createMovieFPS()
{
  snapDir="$SNAP_BASE/$1"
  
  if [ ! -d "$snapDir" ]; then
    logerr "Error : No media files in '$snapDir'"
    exit 2
  fi

  createDir "$OUT_DIR"
  outfile="$OUT_DIR/$1 - $DATE_EXT.mp4"

  if [ "$2" = "today" ]; then
    log "Creating video of $1 from today's images"
    ffmpeg -r "$4" -start_number 1 -pattern_type glob -i "$snapDir/"'*'"$(date '+%F')"'*.jpg' -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  elif [ "$2" = "yesterday" ]; then
    log "Creating video of $1 from yesterday's images"
    ffmpeg -r "$4" -start_number 1 -pattern_type glob -i "$snapDir/"'*'"$(date '+%F' -d "1 day ago")"'*.jpg' -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  elif [ "$2" = "file" ]; then
    if [ ! -f "$3" ]; then
      logerr "ERROR file '$3' not found"
      exit 1
    fi
    log "Creating video of $1 from images in $3"
    ffmpeg -r "$4" -start_number 1 -i "$(cat "$3")" -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  else
    log "Creating video of $1 from all images"
    ffmpeg -r "$4" -start_number 1 -pattern_type glob -i "$snapDir/"'*.jpg' -c:v libx264 -preset ultrafast -c:a copy -pix_fmt yuv420p "$outfile" -hide_banner
  fi

  # need to chance current dir so links work over network mounts
  cwd=`pwd`

  log "Created $outfile"

  cd "$cwd"
}

case $1 in
  savesnap)
    for ((i = 2; i <= $#; i++ )); do
      if [ -z "${CAMS[${!i}]}" ]; then
        logerr "ERROR, can't find camera '${!i}'"
      else
        getSnap "${!i}" "${CAMS[${!i}]}"
      fi
    done
  ;;

  createvideo)
    echo "Would you like a custom framerate?"
    echo "Press [ENTER] for no, or enter an integer number"
    echo "that represents your preferred framerate."
    read -p "FPS> " fps

    if [[ "$fps" -eq "" ]]
    then
      createMovie "${2}" "${3}" "${4}"
    else
      createMovieFPS "${2}" "${3}" "${4}" "$fps"
    fi
    
  ;;

  *)
    logerr "Bad Args use :-"
    logerr "$0 savesnap \"camera name\""
    logerr "$0 createvideo \"camera name\" today"
    logerr "options (today|yesterday|all|filename)"
  ;;

esac



