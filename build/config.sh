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

# Enable SSH
ENABLESSH=0

# Enable auto serial login
# On controller
SERIALAUTOLOGINC=0
# On Px
SERIALAUTOLOGINP=0

# Do we run dist-upgrade?
UPGRADE=1

# Max Px nodes to build for lite/std/full
MAXPLITE=4
MAXPSTD=0
MAXPFULL=0

# Do we build a usbboot/rpiboot image (NFSROOT)
USBBOOTLITE=0
USBBOOTSTD=0
USBBOOTFULL=0
# usbboot compression options
XZ="-v9"

# Space separated list of additional packages to install
INSTALLEXTRA=""

# Load local config overrides
if [ -f config-local.sh ];then
 source ./config-local.sh
fi
