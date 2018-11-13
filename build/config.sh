#!/bin/sh
# Config file for Cluster HAT build

# Revision number
REV=1

# Location of img files (must be unzipped)
SOURCE=./img

# Destination directory where modified images are stored
DEST=./dest

# Directory to mount source/destination files
MNT=./mnt

# Directory to mount source files (only required for usbboot.sh)
MNT2=./mnt2

# Location of Cluster HAT files on target images
CONFIGDIR="/usr/share/clusterhat"

# Default password
PASSWORD=raspberry

# Load local config overrides
if [ -f config-local.sh ];then
 source ./config-local.sh
fi
