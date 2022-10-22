# Calibre Backups 

A quick bash script to backup my Calibre database regularly.  I run Calibre on a Raspberry Pi and I want to make sure the data's backed up.  


```    
$ calibre_backup.sh -h
    Usage: calibre_backup.sh
      -h help 
      -b full path to backup location 
      -l full path to library 
      -c clean (remove calibre files from backup location)
      -w delay time

$ calibre_backup.sh -b /tmp/CalibreBackup -l /opt/Books/ -c -w 10

```

It does some sanity checks (like making sure you're not going to accidentally remove your library), and gives the option to clean the backup folder before a backup.   


It does some basic checks for calibre app locations on MacOS, but if you installed someplace besides the default locations, then you'll have to edit the code.    

YMMV, Use at your own risk, and I don't have windows .   
