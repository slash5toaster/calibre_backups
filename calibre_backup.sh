#!/usr/bin/env bash

# Backup the calibre database

[[ $DEBUG ]] && set -x

SHASUMBIN=$(type -p sha1sum || type -p shasum )
PAUSE_TIME=5
CLEAN_BACKUP=1

usageHelp="Usage: ${0##*/}"
defaultHelp="  -h help "
backupfolderHelp="  -b full path to backup location $BACKUP_FOLDER"
cleanHelp="  -c clean (remove calibre files from backup location)"
libraryHelp="  -l full path to library $BOOK_FOLDER"
pausetimeHelp="  -w delay time"
badOptionHelp="Option not recognised"
#---------------------------------------------------------------

# Functions
#---------------------------------------------------------------

setupPaths()
{
   # for mac users
   # set $CALIBRE_APP to the path of your calibre.app
   # if you have it someplace *other* than the default location

   if [[ $(uname -s) == "Darwin" ]]; then

      if [[ -d /Applications/calibre.app ]]; then
         CALIBRE_APP=/Applications/calibre.app

      elif [[ -d $HOME/Applications/calibre.app ]]; then
         CALIBRE_APP=$HOME/Applications/calibre.app
      fi

      if [[ -n $CALIBRE_APP ]]; then
         PATH=$PATH:$CALIBRE_APP/Contents/MacOS
      fi
   fi

   CALIBREDEBUG=$(type -p calibre-debug)

   if [[ -z ${CALIBREDEBUG} ]]; then
      echo "-----------"
      echo "Can't find backup program calibre-debug"
      echo "Check your path statement"

      if [[ $(uname -s) == "Darwin" ]]; then
         echo "You must export the path to the calibre binaries"
         echo "e.g. export PATH=\$PATH:<path to calibre>/Contents/MacOS/"
         echo
      fi
      exit 2
   fi
}

#---------------------------------------------------------------
printHelpAndExit()
{
  echo "${usageHelp}"
  echo "${defaultHelp}"
  echo "${backupfolderHelp}"
  echo "${libraryHelp}"
  echo "${cleanHelp}"
  echo "${pausetimeHelp}"
  exit $1
}

#---------------------------------------------------------------
printErrorHelpAndExit()
{
   echo
   echo "$@"
   echo
   echo
   printHelpAndExit 1
}
#---------------------------------------------------------------

delayTime ()
{
    local TITLE=${1:-"backing up"}
    local NUMSEC=${2:-$PAUSE_TIME}

    echo "${TITLE} in ${NUMSEC}"
    for (( i = $NUMSEC ; i > 0; i-- )); do
      echo -en "$i "
      sleep 1
    done
    echo
}
#---------------------------------------------------------------

libraryCheck()
{
    # is there library there?
    if [[ ! -e "$BOOK_FOLDER"/metadata.db ]]; then
       echo "$BOOK_FOLDER not a valid calibre library"
       exit 4
    else
      return 0
    fi
}
#--------------------------------------------------------------

prepBackupLocation()
   {
      local SUCCESS=1
      local -a FileCount

      [[ -e "$BACKUP_FOLDER" ]] || mkdir -vp "$BACKUP_FOLDER"

      mapfile -t FileCount< <(ls -A "$BACKUP_FOLDER")

      [[ $DEBUG ]] && echo -e "${BACKUP_FOLDER} has ${#FileCount[@]} files,\n${FileCount[*]}"

      if [[ ${#FileCount[@]} == 0  ]] ; then
         # make sure it is clean
         SUCCESS=0
      else
         if [[ $CLEAN_BACKUP == 0 ]]; then
            # delete all files in the backup folder

            if [[ -e "$BACKUP_FOLDER"/metadata.db ]] ; then
               echo "$BACKUP_FOLDER looks like a library folder, Exiting!!"
               exit 8
            fi

            delayTime "Deleting files in ${BACKUP_FOLDER}" 2

            for file in "${FileCount[@]}"; do
               rm -vf "${BACKUP_FOLDER}/${file:?}" || exit 5
            done && SUCCESS=0

         else
            echo "Backup directory $BACKUP_FOLDER not empty - backup requires an empty folder"
            exit 2
         fi
      fi

      return $SUCCESS
   }
#---------------------------------------------------------------

backupManifest()
   {
      cd "$BACKUP_FOLDER" || exit 3
      find . -type f \
      | sort \
      | sed -e 's/\.\///' \
      | grep -v "sha1$" \
      | xargs $SHASUMBIN \
      | tee "$BACKUP_FOLDER"/CalibreBackup.sha1

   }
#---------------------------------------------------------------

backupCalibre()
   {
     local SUCCESS=1

     delayTime "Backing up ${BOOK_FOLDER} to ${BACKUP_FOLDER}" $PAUSE_TIME

      ${CALIBREDEBUG} \
         --export-all-calibre-data \
         "$BACKUP_FOLDER" \
         "$BOOK_FOLDER" \
      && SUCCESS=0
     return $SUCCESS
   }
#---------------------------------------------------------------

#######################################
while getopts "hcb:l:w:" optionName; do
   case "$optionName" in
      h)  printHelpAndExit 0;;
      c)  CLEAN_BACKUP=0;;
      b)  BACKUP_FOLDER="$OPTARG";;
      l)  BOOK_FOLDER="$OPTARG";;
      w)  PAUSE_TIME="${OPTARG:=5}";;
      [?])  printErrorHelpAndExit "${badOptionHelp}";;
   esac
done

if [[ $DEBUG ]]; then
  echo "Backup folder is $BACKUP_FOLDER"
  echo "Book folder is $BOOK_FOLDER"
  echo "Pause time is $PAUSE_TIME, Clean is $CLEAN_BACKUP, Debug is $DEBUG"
fi

if [[ -n "$BACKUP_FOLDER"  ]] ; then
   setupPaths
   libraryCheck && \
   prepBackupLocation && \
   backupCalibre && \
   backupManifest
else
   printHelpAndExit 2
fi
