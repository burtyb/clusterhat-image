#!/bin/bash -x

#echo "Press CTRL+C to proceed."
#trap "pkill -f 'sleep 1h'" INT
#trap "set +x ; sleep 1h ; set -x" DEBUG

source ./config.sh

if [ $# -ne 1 ]; then
 echo "Usage: $0 <version>"
 echo " Where version is 2017-08-16 in 2017-08-16-raspbian-stretch-lite.img"
 echo " Builds lite & desktop images for controller, p1, p2, p3 and p4"
 echo " SOURCE=$SOURCE (see config.sh)"
 echo " DEST=$DEST"
 echo ""
 exit
fi

# Check directories exist
if [ ! -d "$MNT" ] ;then
 echo "\$MNT directory does not exist."
 exit
fi
if [ ! -d "$MNT2" ]; then
 echo "\$MNT2 directory does not exist."
 exit
fi

# Get version from command line
VER=$1

# Detect which source files we have (lite/desktop/full)
# Build array of Raspbian images (lite/std/full) to build
# SOURCES[] = "<Source filename>|<Dest filename>|<Variable name>"

CNT=0

# Check for Raspbian stretch
if [ -f "$SOURCE/$VER-raspbian-stretch-lite.img" ];then
 SOURCES[$CNT]="$VER-raspbian-stretch-lite.img|$VER-$REV-stretch-ClusterCTRL-armhf-lite|LITE|STRETCH"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspbian-stretch.img" ];then
 SOURCES[$CNT]="$VER-raspbian-stretch.img|$VER-$REV-stretch-ClusterCTRL-armhf|STD|STRETCH"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspbian-stretch-full.img" ];then
 SOURCES[$CNT]="$VER-raspbian-stretch-full.img|$VER-$REV-stretch-ClusterCTRL-armhf-full|FULL|STRETCH"
 let CNT=$CNT+1
fi

# Check for Raspbian buster
if [ -f "$SOURCE/$VER-raspbian-buster-lite.img" ];then
 SOURCES[$CNT]="$VER-raspbian-buster-lite.img|$VER-$REV-buster-ClusterCTRL-armhf-lite|LITE|BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspbian-buster.img" ];then
 SOURCES[$CNT]="$VER-raspbian-buster.img|$VER-$REV-buster-ClusterCTRL-armhf-std|STD|BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspbian-buster-full.img" ];then
 SOURCES[$CNT]="$VER-raspbian-buster-full.img|$VER-$REV-buster-ClusterCTRL-armhf-full|FULL|BUSTER"
 let CNT=$CNT+1
fi

# Check for Raspberry Pi OS (old naming scheme)
if [ -f "$SOURCE/$VER-raspios-buster-lite-armhf.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-lite-armhf.img|$VER-$REV-buster-ClusterCTRL-armhf-lite|LITE|RASPIOS32BUSTER"
 let CNT=$CNT+1
fi
#if [ -f "$SOURCE/$VER-raspios-buster-armhf.img" ];then
# SOURCES[$CNT]="$VER-raspios-buster-armhf.img|$VER-$REV-buster-ClusterCTRL-armhf|STD|RASPIOS32BUSTER"
# let CNT=$CNT+1
#fi
if [ -f "$SOURCE/$VER-raspios-buster-full-armhf.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-full-armhf.img|$VER-$REV-buster-ClusterCTRL-armhf-full|FULL|RASPIOS32BUSTER"
 let CNT=$CNT+1
fi

# Check for Raspberry Pi OS 32-bit
if [ -f "$SOURCE/$VER-raspios-buster-armhf-lite.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-armhf-lite.img|$VER-$REV-buster-ClusterCTRL-armhf-lite|LITE|RASPIOS32BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-buster-armhf.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-armhf.img|$VER-$REV-buster-ClusterCTRL-armhf|STD|RASPIOS32BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-buster-armhf-full.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-armhf-full.img|$VER-$REV-buster-ClusterCTRL-armhf-full|FULL|RASPIOS32BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bullseye-armhf-lite.img" ];then
 SOURCES[$CNT]="$VER-raspios-bullseye-armhf-lite.img|$VER-$REV-bullseye-ClusterCTRL-armhf-lite|LITE|RASPIOS32BULLSEYE"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bullseye-armhf.img" ];then
 SOURCES[$CNT]="$VER-raspios-bullseye-armhf.img|$VER-$REV-bullseye-ClusterCTRL-armhf|STD|RASPIOS32BULLSEYE"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bullseye-armhf-full.img" ];then
 SOURCES[$CNT]="$VER-raspios-bullseye-armhf-full.img|$VER-$REV-bullseye-ClusterCTRL-armhf-full|FULL|RASPIOS32BULLSEYE"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bookworm-armhf.img" ];then
 SOURCES[$CNT]="$VER-raspios-bookworm-armhf.img|$VER-$REV-bookworm-ClusterCTRL-armhf|STD|RASPIOS32BOOKWORM"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bookworm-armhf-lite.img" ];then
 SOURCES[$CNT]="$VER-raspios-bookworm-armhf-lite.img|$VER-$REV-bookworm-ClusterCTRL-armhf-lite|LITE|RASPIOS32BOOKWORM"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bookworm-armhf-full.img" ];then
 SOURCES[$CNT]="$VER-raspios-bookworm-armhf-full.img|$VER-$REV-bookworm-ClusterCTRL-armhf-full|FULL|RASPIOS32BOOKWORM"
 let CNT=$CNT+1
fi

# Check for Raspberry Pi OS 64-bit
if [ -f "$SOURCE/$VER-raspios-buster-arm64.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-arm64.img|$VER-$REV-buster-ClusterCTRL-arm64|STD|RASPIOS64BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-buster-arm64-lite.img" ];then
 SOURCES[$CNT]="$VER-raspios-buster-arm64-lite.img|$VER-$REV-buster-ClusterCTRL-arm64-lite|LITE|RASPIOS64BUSTER"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bullseye-arm64.img" ];then
 SOURCES[$CNT]="$VER-raspios-bullseye-arm64.img|$VER-$REV-bullseye-ClusterCTRL-arm64|STD|RASPIOS64BULLSEYE"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bullseye-arm64-lite.img" ];then
 SOURCES[$CNT]="$VER-raspios-bullseye-arm64-lite.img|$VER-$REV-bullseye-ClusterCTRL-arm64-lite|LITE|RASPIOS64BULLSEYE"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bullseye-arm64-full.img" ];then
 SOURCES[$CNT]="$VER-raspios-bullseye-arm64-full.img|$VER-$REV-bullseye-ClusterCTRL-arm64-full|FULL|RASPIOS64BULLSEYE"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bookworm-arm64.img" ];then
 SOURCES[$CNT]="$VER-raspios-bookworm-arm64.img|$VER-$REV-bookworm-ClusterCTRL-arm64|STD|RASPIOS64BOOKWORM"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bookworm-arm64-lite.img" ];then
 SOURCES[$CNT]="$VER-raspios-bookworm-arm64-lite.img|$VER-$REV-bookworm-ClusterCTRL-arm64-lite|LITE|RASPIOS64BOOKWORM"
 let CNT=$CNT+1
fi
if [ -f "$SOURCE/$VER-raspios-bookworm-arm64-full.img" ];then
 SOURCES[$CNT]="$VER-raspios-bookworm-arm64-full.img|$VER-$REV-bookworm-ClusterCTRL-arm64-full|FULL|RASPIOS64BOOKWORM"
 let CNT=$CNT+1
fi

if [ $CNT -eq 0 ];then
 echo "No source file(s) found"
 exit
fi

# Should we use qemu to modify the images
# On Ubuntu this can be used after running
# "apt install qemu-user kpartx qemu-user-static"
QEMU=0
MACHINE=`uname -m`
if ! [ "$MACHINE" = "armv7l" -o "$MACHINE" = "aarch64" ] ;then
 if [ -f "/usr/bin/qemu-arm-static" ];then
  QEMU=1
 else 
  echo 'Unable to run as we're not running on ARM and we don't have "/usr/bin/qemu-arm-static"'
  exit
 fi
fi

# Make sure we have zerofree
which zerofree >/dev/null 2>&1
if [ $? -eq 1 ];then
 echo "Installing zerofree"
 apt install -y zerofree
fi

# Clean env variables
export LC_ALL=C
unset LANGUAGE
unset LC_MESSAGES
unset LANG

# Loop each image type
for BUILD in "${SOURCES[@]}"; do
 # Extract '|' separated variables
 IFS='|' read -ra IMAGE <<< "$BUILD"
 SOURCEFILENAME=${IMAGE[0]}
 DESTFILENAME=${IMAGE[1]}
 VARNAME=${IMAGE[2]}
 RELEASE=${IMAGE[3]}

 if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ];then
  FW="boot/firmware"
 else
  FW="boot"
 fi

 # Create the bridged controller

 if [ -f "$DEST/$DESTFILENAME-CBRIDGE.img" ];then
  echo "Skipping $TYPENAME build"
  echo " $DEST/$DESTFILENAME-CBRIDGE.img exists"
 else
  echo "Building $TYPENAME"
  echo " Copying source image"
  cp "$SOURCE/$SOURCEFILENAME" "$DEST/$DESTFILENAME-CBRIDGE.img"

  # Do we need to grow the image (second partition)?
  GROW="GROW$VARNAME" # Build variable name to check
  if [ ! ${!GROW} = "0" ];then
   # Get PTUUID
   export $(blkid -o export "$DEST/$DESTFILENAME-CBRIDGE.img")
   truncate "$DEST/$DESTFILENAME-CBRIDGE.img" --size=+${!GROW}
   parted --script "$DEST/$DESTFILENAME-CBRIDGE.img" resizepart 2 100%
   # Set PTUUID
   fdisk "$DEST/$DESTFILENAME-CBRIDGE.img" <<EOF > /dev/null
p
x
i
0x$PTUUID
r
p
w
EOF
  fi  

  LOOP=`losetup -fP --show $DEST/$DESTFILENAME-CBRIDGE.img`
  sleep $SLEEP

  # If the image has been grown resize the filesystem
  if [ ! ${!GROW} = "0" ];then
   e2fsck -fp ${LOOP}p2
   resize2fs -p ${LOOP}p2
  fi

  mount -o noatime,nodiratime ${LOOP}p2 $MNT
  mount ${LOOP}p1 $MNT/$FW
  mount -o bind /proc $MNT/proc
  mount -o bind /dev $MNT/dev

  chroot $MNT apt -y purge wolfram-engine

  # Get any updates / install and remove pacakges
  chroot $MNT apt update -y
  if [ $UPGRADE = "1" ]; then
   chroot $MNT /bin/bash -c 'APT_LISTCHANGES_FRONTEND=none apt -y dist-upgrade'
  fi

  if [ $RELEASE = "STRETCH" ];then
   INSTALLEXTRA+=" wiringpi python-smbus python-usb python-libusb1"
  elif [ $RELEASE = "BUSTER" -o $RELEASE = "RASPIOS32BUSTER" -o $RELEASE = "RASPIOS64BUSTER" \
	-o $RELEASE = "RASPIOS32BULLSEYE" -o $RELEASE = "RASPIOS64BULLSEYE" ]; then
   INSTALLEXTRA+=" initramfs-tools-core python3-smbus python3-usb python3-libusb1 ifmetric"
  elif [ $RELEASE =  "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
   INSTALLEXTRA+=" initramfs-tools-core python3-smbus python3-usb python3-libusb1 ifmetric python3-libgpiod ifupdown"
  fi

  chroot $MNT apt -y install rpiboot bridge-utils screen minicom subversion git libusb-1.0-0-dev nfs-kernel-server busybox $INSTALLEXTRA

  # Setup ready for iptables for NAT for NAT/WiFi use
  # Preseed answers for iptables-persistent install
  chroot $MNT /bin/bash -c "echo 'iptables-persistent iptables-persistent/autosave_v4 boolean false' | debconf-set-selections"
  chroot $MNT /bin/bash -c "echo 'iptables-persistent iptables-persistent/autosave_v6 boolean false' | debconf-set-selections"

  chroot $MNT /bin/bash -c 'APT_LISTCHANGES_FRONTEND=none apt -y install iptables-persistent'

#  # Remove ModemManager
#  chroot $MNT systemctl disable ModemManager.service
#  chroot $MNT apt -y purge modemmanager
#  chroot $MNT apt-mark hold modemmanager

  # Add more resolvers
  echo -e "nameserver 8.8.4.4\nnameserver 2001:4860:4860::8888\nnameserver 2001:4860:4860::8844" >> $MNT/etc/resolv.conf

  echo '#net.ipv4.ip_forward=1 # ClusterCTRL' >> $MNT/etc/sysctl.conf
  cat << EOF >> $MNT/etc/iptables/rules.v4
# Generated by iptables-save v1.6.0 on Fri Mar 13 00:00:00 2018
*filter
:INPUT ACCEPT [7:1365]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A FORWARD -i br0 ! -o br0 -j ACCEPT
-A FORWARD -o br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
COMMIT
# Completed on Fri Mar 13 00:00:00 2018
# Generated by iptables-save v1.6.0 on Fri Mar 13 00:00:00 2018
*nat
:PREROUTING ACCEPT [8:1421]
:INPUT ACCEPT [7:1226]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 172.19.181.0/24 ! -o br0 -j MASQUERADE
COMMIT
# Completed on Fri Mar 13 00:00:00 2018
EOF

  # Set custom password
  if [ -f $MNT/usr/bin/rename-user ];then
   if [ ! -z $USERNAME ] && [ ! -z $PASSWORD ];then
    PASSWORDE=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
    echo "$USERNAME:$PASSWORDE" >> $MNT/$FW/userconf.txt
   fi
  else
   chroot $MNT /bin/bash -c "echo 'pi:$PASSWORD' | chpasswd"
  fi

  # Should we enable SSH?
  if [ $ENABLESSH = "1" ];then
   touch $MNT/$FW/ssh
  fi

  # Should we update with rpi-update?
  if [ ! -z $RPIUPDATE ];then
   export ROOT_PATH=$MNT
   export BOOT_PATH=$MNT/$FW
   export SKIP_WARNING=1
   export SKIP_BACKUP=1
   rpi-update "$RPIUPDATE"
  fi

  # Disable APIPA addresses on ethpiX and set fallback IPs

  # We give this an "unconfigured" IP of 172.19.181.253
  # Pi Zeros should be reconfigured to 172.19.181.X where X is the P number
  # NAT Controller is on 172.19.181.254
  # A USB network (usb0) device plugged into the controller will have fallback IP of 172.19.181.253

  if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ];then
   cat << EOF >> $MNT/etc/dhcp/dhclient.conf
# START ClusterCTRL config
timeout 10;
initial-interval 2;
lease { # Px
  interface "usb0";
  fixed-address 172.19.181.253; # ClusterCTRL Px
  option subnet-mask 255.255.255.0;
  option routers 172.19.181.254;
  option domain-name-servers 8.8.8.8;
  renew never;
  rebind never;
  expire never;
}

lease { # Controller
  interface "br0";
  fixed-address 172.19.181.254;
  option subnet-mask 255.255.255.0;
  option domain-name-servers 8.8.8.8;
  renew never;
  rebind never;
  expire never;
}
# END ClusterCTRL config
EOF
  else 
   cat << EOF >> $MNT/etc/dhcpcd.conf
# ClusterCTRL
reboot 15
denyinterfaces ethpi* ethupi* ethupi*.10 brint eth0 usb0.10

profile clusterctrl_fallback_usb0
static ip_address=172.19.181.253/24 #ClusterCTRL
static routers=172.19.181.254
static domain_name_servers=8.8.8.8 208.67.222.222

profile clusterctrl_fallback_br0
static ip_address=172.19.181.254/24

interface usb0
fallback clusterctrl_fallback_usb0

interface br0
fallback clusterctrl_fallback_br0
EOF
  fi

  # Enable uart with login
  SERIALCONSOLE=$(grep -c "^enable_uart=1" $MNT/$FW/config.txt)
  if [ $SERIALCONSOLE -eq 0 ]; then
   echo "enable_uart=1" >>  $MNT/$FW/config.txt
  fi
  #chroot $MNT /bin/bash -c "raspi-config nonint do_serial 0"

  # Enable I2C (used for I/O expander on Cluster HAT v2.x)
  chroot $MNT /bin/bash -c "raspi-config nonint do_i2c 0"

  # Change the hostname to "cbridge"
  sed -i "s#^127.0.1.1.*#127.0.1.1\tcbridge#g" $MNT/etc/hosts
  echo "cbridge" > $MNT/etc/hostname

  echo -e "mountd: 172.19.180.\nrpcbind: 172.19.180.\n" >> $MNT/etc/hosts.allow
  echo -e "mountd: ALL\nrpcbind: ALL\n" >> $MNT/etc/hosts.deny

  # Enable console on UART
  if [ "$SERIALAUTOLOGIN" = "1" ];then
   if [ $RELEASE = "BUSTER" -o $RELEASE = "RASPIOS32BUSTER" -o $RELEASE = "RASPIOS64BUSTER" \
	-o $RELEASE = "RASPIOS32BULLSEYE" -o $RELEASE = "RASPIOS64BULLSEYE" \
	-o $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ];then
    mkdir -p $MNT/etc/systemd/system/serial-getty@ttyS0.service.d/
    cat > $MNT/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF
   fi
   if [ $RELEASE = "STRETCH" ];then
    sed -i "s#agetty --keep-baud#agetty --autologin pi --keep-baud#" $MNT/lib/systemd/system/serial-getty@.service
   fi
  fi

  # Extract files
  (tar --exclude=.git -cC ../files/ -f - .) | (chroot $MNT tar -xC /)

  # Disable the auto filesystem resize and convert to bridged controller
  sed -i 's# init=/usr/lib/raspi-config/init_resize.sh##' $MNT/$FW/cmdline.txt
  sed -i 's# init=/usr/lib/raspberrypi-sys-mods/firstboot##' $MNT/$FW/cmdline.txt
  sed -i 's#$# init=/usr/sbin/reconfig-clusterctrl cbridge#' $MNT/$FW/cmdline.txt

  # Setup directories for rpiboot
  mkdir -p $MNT/var/lib/clusterctrl/boot
  mkdir $MNT/var/lib/clusterctrl/nfs
  if [ -z $BOOTCODE ];then
   ln -fs /$FW/bootcode.bin $MNT/var/lib/clusterctrl/boot/
  elif [ ! $BOOTCODE = "none" ];then
   wget -O $MNT/var/lib/clusterctrl/$FW/bootcode.bin $BOOTCODE
  fi

  # Enable clusterctrl init
  chroot $MNT systemctl enable clusterctrl-init

  # Enable rpiboot for booting without SD cards
  chroot $MNT systemctl enable clusterctrl-rpiboot
  # Disable nfs server (rely on clusterctrl-rpiboot to start it if needed)
  chroot $MNT systemctl disable nfs-kernel-server

  # Setup NFS exports for NFSROOT
  for ((P=1;P<=252;P++));do
   echo "/var/lib/clusterctrl/nfs/p$P 172.19.180.$P(rw,sync,no_subtree_check,no_root_squash)" >> $MNT/etc/exports
   mkdir "$MNT/var/lib/clusterctrl/nfs/p$P"
  done

  # Setup config.txt file
  echo -e "# Load overlay to allow USB Gadget devices\ndtoverlay=dwc2,dr_mode=host" >> $MNT/$FW/config.txt
  echo -e "# Use XHCI USB 2 Controller for Cluster HAT Controllers\n[pi4]\notg_mode=1 # Controller only\n[cm4]\notg_mode=0 # Unless CM4\n[all]\n" >> $MNT/$FW/config.txt

  if [ $RELEASE = "RASPIOS64BULLSEYE" ] && [ ! -f "$MNT/$FW/bcm2710-rpi-zero-2.dtb" ];then
   cp $MNT/$FW/bcm2710-rpi-3-b.dtb $MNT/$FW/bcm2710-rpi-zero-2.dtb
  fi

  if [ $USERSYSLOG -eq 1 ];then
   chroot $MNT apt -y install rsyslog
  fi

  rm -f $MNT/etc/ssh/*key*
  chroot $MNT apt -y autoremove --purge
  chroot $MNT apt clean

  umount $MNT/dev
  umount $MNT/proc
  umount $MNT/$FW
  umount $MNT

  sleep $SLEEP
  zerofree -v ${LOOP}p2
  sleep $SLEEP

  losetup -d $LOOP

  if [ "$FINALISEIMG" != "" ];then
   "$FINALISEIMG" "$FINALISEIMGOPT" "$DEST/$DESTFILENAME-CBRIDGE.img"
   LOOP=`losetup -fP --show $DEST/$DESTFILENAME-CBRIDGE.img`
   sleep $SLEEP
   zerofree -v ${LOOP}p2
   losetup -d $LOOP
  fi

 fi
 
 # Build the usbboot image if required

 USBBOOT="USBBOOT$VARNAME" # Build variable name to check
 if [ ${!USBBOOT} = "1" ] && [ -f "$DEST/$DESTFILENAME-CBRIDGE.img" ] && [ ! -f "$DEST/$DESTFILENAME-usbboot.tar.xz" ] && [ ! -f "$DEST/$DESTFILENAME-usbboot.tar" ];then
  echo "Creating $VARNAME usbboot"

  if [ -e "$MNT2/root" ];then
   echo "ERROR: usbboot temp directory $MNT2/root already exists"
   exit
  fi

  LOOP=`losetup -rfP --show $DEST/$DESTFILENAME-CBRIDGE.img`
  sleep $SLEEP

  mount -o ro ${LOOP}p2 $MNT
  mount -o ro ${LOOP}p1 $MNT/$FW

  mkdir "$MNT2/root"
  tar -cC "$MNT" .|tar -xC "$MNT2/root/"

  umount $MNT/$FW
  umount $MNT
  losetup -d $LOOP

  mount -o bind /proc $MNT2/root/proc

  sed -i "/ \/ /d" $MNT2/root/etc/fstab
  sed -i "/ \/boot/d" $MNT2/root/etc/fstab
  
  sed -i "s#fsck.repair=yes#fsck.mode=skip#" $MNT2/root/$FW/cmdline.txt
  chroot $MNT2/root/ systemctl disable clusterctrl-rpiboot

  # Copy network defaults if needed
  if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
   rm -f $MNT2/root/etc/network/interfaces.d/clusterctrl
   cp $MNT2/root/usr/share/clusterctrl/interfaces.bookworm.p $MNT2/root/etc/network/interfaces.d/clusterctrl
  fi

  if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
   echo "172.19.180.254:/var/lib/clusterctrl/nfs/p253/boot/firmware /boot/firmware nfs defaults 0 0" >> $MNT2/root/etc/fstab
   echo "FWLOC='/$FW/'" > $MNT2/root/etc/default/raspberrypi-sys-mods
   echo -e "[Service]\nExecStop=\nExecStop=/sbin/ifdown -a --read-environment --exclude=lo --exclude=usb0 --exclude=usb0.10" > $MNT2/root/etc/systemd/system/networking.service.d/override.conf
  fi
  sed -i "s/^dtoverlay=dwc2.*$/dtoverlay=dwc2,dr_mode=peripheral/" $MNT2/root/$FW/config.txt

  echo -e "dwc2\n8021q\nuio_pdrv_genirq\nuio\nusb_f_acm\nu_serial\nusb_f_ecm\nu_ether\nlibcomposite\nudc_core\nipv6\nusb_f_rndis\n" >> $MNT2/root/etc/initramfs-tools/modules
  if [ $RELEASE = "RASPIOS64BUSTER" -o $RELEASE = "RASPIOS64BULLSEYE" ];then
   echo -e "\n[all]\ninitramfs initramfs8.img\ndtparam=sd_poll_once=on\n" >> $MNT2/root/$FW/config.txt
  elif [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ];then
   echo "Skipping initramfs config"
  elif [ $RELEASE = "RASPIOS32BULLSEYE" ];then
   echo -e "\n[pi0]\ninitramfs initramfs.img\n[pi02]\ninitramfs initramfs7.img\n[pi1]\ninitramfs initramfs.img\n[pi2]\ninitramfs initramfs7.img\n[pi3]\ninitramfs initramfs7.img\n[pi4]\ninitramfs initramfs8.img\n[all]\ndtparam=sd_poll_once=on\n" >> $MNT2/root/$FW/config.txt
  else 
   echo -e "\n[pi0]\ninitramfs initramfs.img\n[pi02]\ninitramfs initramfs7.img\n[pi1]\ninitramfs initramfs.img\n[pi2]\ninitramfs initramfs7.img\n[pi3]\ninitramfs initramfs7.img\n[pi4]\ninitramfs initramfs7l.img\n[all]\ndtparam=sd_poll_once=on\n" >> $MNT2/root/$FW/config.txt
  fi

  # Enable uart with login
  SERIALCONSOLE=$(grep -c "^enable_uart=1" $MNT2/root/$FW/config.txt)
  if [ $SERIALCONSOLE -eq 0 ]; then
   echo "enable_uart=1" >>  $MNT2/root/$FW/config.txt
  fi
  #chroot $MNT2/root/ /bin/bash -c "raspi-config nonint do_serial 0"

  sed -i "s# init=.*##" $MNT2/root/$FW/cmdline.txt
  if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
   sed -i '$ s#$# init=/usr/lib/raspberrypi-sys-mods/firstboot#'  $MNT2/root/$FW/cmdline.txt
  fi
  sed -i "s#^MODULES=.*#MODULES=netboot#" $MNT2/root/etc/initramfs-tools/initramfs.conf
  echo "BOOT=nfs" >> $MNT2/root/etc/initramfs-tools/initramfs.conf
  if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
   echo "COMPRESS already set"
  else
   sed -i "s#^COMPRESS=.*#COMPRESS=xz#" $MNT2/root/etc/initramfs-tools/initramfs.conf
  fi
  sed -i "s#root=.* rootfstype=ext4#root=/dev/nfs nfsroot=172.19.180.254:/var/lib/clusterctrl/nfs/p252 rw ip=172.19.180.252:172.19.180.254::255.255.255.0:p252:usb0.10:static#" $MNT2/root/$FW/cmdline.txt

  # Enable console on gadget serial

  chroot $MNT2/root/ /bin/bash -c "systemctl enable serial-getty@ttyGS0"

  if [ "$SERIALAUTOLOGIN" = "1" ];then
   if [ $RELEASE = "BUSTER" -o $RELEASE = "RASPIOS32BUSTER" -o $RELEASE = "RASPIOS64BUSTER" \
	$RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
    mkdir -p $MNT2/root/etc/systemd/system/serial-getty@ttyS0.service.d/
    cat > $MNT2/root/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF
   fi
   if [ $RELEASE = "STRETCH" ];then
    sed -i "s#agetty --keep-baud#agetty --autologin pi --keep-baud#" $MNT2/root/lib/systemd/system/serial-getty@.service
   fi
  fi

  if [ $RELEASE = "RASPIOS64BOOKWORM" -o $RELEASE = "RASPIOS32BOOKWORM" ]; then
   chroot $MNT2/root /bin/bash -c "update-initramfs -k all -u"
  else
   # 3A+/CM3/CM3+
   for V in `(cd $MNT2/root/lib/modules/;ls|grep v7|grep -v v7l|sort -V|tail -n1)`; do
    chroot $MNT2/root /bin/bash -c "mkinitramfs -o /boot/initramfs7.img $V"
   done
 
    # A+/Pi Zero/CM1
   for V in `(cd $MNT2/root/lib/modules/;ls|grep -v v|sort -V|tail -n1)`; do
    chroot $MNT2/root /bin/bash -c "mkinitramfs -o /boot/initramfs.img $V"
   done
 
   # 4B (32bit)
   for V in `(cd $MNT2/root/lib/modules/;ls|grep v7l|sort -V|tail -n1)`; do
    chroot $MNT2/root /bin/bash -c "mkinitramfs -o /boot/initramfs7l.img $V"
   done
 
   # 4B (64bit)
   for V in `(cd $MNT2/root/lib/modules/;ls|grep v8|sort -V|tail -n1)`; do
    chroot $MNT2/root /bin/bash -c "mkinitramfs -o /boot/initramfs8.img $V"
   done
  fi

  umount $MNT2/root/proc

  if [ $USBBOOTCOMPRESS -eq 1 ];then
   tar -c -C "$MNT2/root" . | xz $XZ > "$DEST/$DESTFILENAME-usbboot.tar.xz"
  else 
   tar -c -C "$MNT2/root" -f "$DEST/$DESTFILENAME-usbboot.tar" .
  fi

  rm -rf "$MNT2/root"

 else
  echo "Skipping $VARNAME usbboot"
 fi

 # Build NAT image

 if [ -f $DEST/$DESTFILENAME-CNAT.img ];then
   echo "Skipping $VARNAME NAT (file exists)"
  else
   echo "Creating $VARNAME NAT"
   cp $DEST/$DESTFILENAME-CBRIDGE.img $DEST/$DESTFILENAME-CNAT.img
   LOOP=`losetup -fP --show $DEST/$DESTFILENAME-CNAT.img`
   sleep $SLEEP
   mount ${LOOP}p1 $MNT
   sed -i "s# init=.*# init=/usr/sbin/reconfig-clusterctrl cnat#" $MNT/cmdline.txt
   umount $MNT

   losetup -d $LOOP
  fi


 # Build Px images as required

 MAXP="MAXP$VARNAME" # Build variable name to check
 if [ ${!MAXP} -gt 0 ] && [ ${!MAXP} -lt 253 ] && [ -f $DEST/$DESTFILENAME-CBRIDGE.img ];then
  for ((P=1;P<=${!MAXP};P++));do
   if [ -f $DEST/$DESTFILENAME-p$P.img ];then
    echo "Skipping $VARNAME P$P (file exists)"
   else
    echo "Creating $VARNAME P$P"
    cp $DEST/$DESTFILENAME-CBRIDGE.img $DEST/$DESTFILENAME-p$P.img
    LOOP=`losetup -fP --show $DEST/$DESTFILENAME-p$P.img`
    sleep $SLEEP

    mount ${LOOP}p1 $MNT
    sed -i "s# init=.*# init=/usr/sbin/reconfig-clusterctrl p$P#" $MNT/cmdline.txt
    umount $MNT

    losetup -d $LOOP
   fi
  done
 fi
  
done
