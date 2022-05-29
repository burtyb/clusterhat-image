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

# Default username/password (both must be set)
# These details are added to userconf.txt in the boot partition.
USERNAME=""
PASSWORD="raspberry"

# Enable SSH
ENABLESSH=0

# Enable auto serial login
SERIALAUTOLOGIN=0

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
USBBOOTCOMPRESS=1

# Grow second partition (use 0 for no resize or size and unit like "500M", "1G", etc)
GROWLITE="0"
GROWFULL="0"
GROWSTD="0"

# Space separated list of additional packages to install
INSTALLEXTRA=""

# If set run rpi-update with this hash (kernel/firmware)
RPIUPDATE=""

# If set download this bootcode.bin from this URL
BOOTCODE=""

# Command to run after image is ready (pishrink.sh for example)
# image name is appended to the end of command
FINALISEIMG=""

# Load local config overrides
if [ -f config-local.sh ];then
 source ./config-local.sh
fi
