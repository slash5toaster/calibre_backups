#!/usr/bin/env python3

import os
import sys
import time
import argparse
import subprocess
import hashlib
import glob

def setup_paths():
    global CALIBREDEBUG
    if sys.platform == "darwin":
        CALIBRE_APP = None
        if os.path.isdir("/Applications/calibre.app"):
            CALIBRE_APP = "/Applications/calibre.app"
        elif os.path.isdir(os.path.join(os.environ['HOME'], "Applications/calibre.app")):
            CALIBRE_APP = os.path.join(os.environ['HOME'], "Applications/calibre.app")
        if CALIBRE_APP is not None:
            os.environ['PATH'] += os.pathsep + os.path.join(CALIBRE_APP, "Contents/MacOS")
    CALIBREDEBUG = subprocess.getoutput("which calibre-debug")
    if not CALIBREDEBUG:
        print("Can't find backup program calibre-debug")
        print("Check your path statement")
        if sys.platform == "darwin":
            print("You must export the path to the calibre binaries")
            print("e.g. export PATH=$PATH:<path to calibre>/Contents/MacOS/")
        sys.exit(2)

def delay_time(title="backing up", num_sec=5):
    print(f"{title} in {num_sec}")
    for i in range(num_sec, 0, -1):
        print(f"{i} ", end="")
        time.sleep(1)
    print()

def library_check():
    if not os.path.exists(os.path.join(BOOK_FOLDER, "metadata.db")):
        print(f"{BOOK_FOLDER} not a valid calibre library")
        sys.exit(4)

def prep_backup_location():
    if not os.path.exists(BACKUP_FOLDER):
        os.makedirs(BACKUP_FOLDER)
    file_count = len(os.listdir(BACKUP_FOLDER))
    if file_count == 0:
        return True
    else:
        if CLEAN_BACKUP == 0:
            if os.path.exists(os.path.join(BACKUP_FOLDER, "metadata.db")):
                print(f"{BACKUP_FOLDER} looks like a library folder, Exiting!!")
                sys.exit(8)
            delay_time(f"Deleting files in {BACKUP_FOLDER}", PAUSE_TIME)
            files = glob.glob(os.path.join(BACKUP_FOLDER, '*'))
            for f in files:
                os.remove(f)
            return True
        else:
            print(f"Backup directory {BACKUP_FOLDER} not empty - backup requires an empty folder")
            sys.exit(2)

def backup_manifest():
    os.chdir(BACKUP_FOLDER)
    files = sorted(glob.glob('**', recursive=True))
    with open(os.path.join(BACKUP_FOLDER, "CalibreBackup.sha1"), 'w') as f:
        for file in files:
            if file != "CalibreBackup.sha1":
                sha1_hash = hashlib.sha1()
                with open(file, "rb") as fi:
                    for byte_block in iter(lambda: fi.read(4096), b""):
                        sha1_hash.update(byte_block)
                f.write(f"{sha1_hash.hexdigest()} {file}\n")

def backup_calibre():
    delay_time(f"Backing up {BOOK_FOLDER} to {BACKUP_FOLDER}", PAUSE_TIME)
    subprocess.run([CALIBREDEBUG, "--export-all-calibre-data", BACKUP_FOLDER, BOOK_FOLDER])

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--clean", help="clean (remove calibre files from backup location)", action="store_true", default=False)
    parser.add_argument("-b", "--backup", help="full path to backup location")
    parser.add_argument("-l", "--library", help="full path to library")
    parser.add_argument("-w", "--wait", help="delay time", type=int, default=5)
    args = parser.parse_args()

    CLEAN_BACKUP = args.clean
    BACKUP_FOLDER = args.backup
    BOOK_FOLDER = args.library
    PAUSE_TIME = args.wait

    if not BACKUP_FOLDER or not BOOK_FOLDER:
        parser.print_help()
        sys.exit(2)

    setup_paths()
    library_check()
    if prep_backup_location():
        backup_calibre()
        backup_manifest()