#!/bin/bash

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

# Get version from command line
VER=$1

# Detect which source files we have (lite/desktop)
FOUND=0
if [ -f "$SOURCE/$VER-raspbian-stretch-lite.img" ];then
 LITE=y
 FOUND=1
fi
if [ -f "$SOURCE/$VER-raspbian-stretch.img" ];then
 DESKTOP=y
 FOUND=1
fi

if [ $FOUND -eq 0 ];then
 echo "No source file found"
 exit
fi

# Make sure we have kpartx & git
which kpartx >/dev/null 2>&1
if [ $? -eq 1 ];then
 echo "Installing kpartx"
 apt-get install -y kpartx
fi
which git >/dev/null 2>&1
if [ $? -eq 1 ];then
 echo "Installing git"
 apt-get install -y git
fi

if [ "$LITE" = "y" ];then
 if [ -f "$DEST/ClusterHAT-$VER-lite-$REV-controller.img" ];then
  echo "Skipping LITE build"
  echo " $DEST/ClusterHAT-$VER-lite-$REV-controller.img exists"
 else
  echo "Building LITE"
  echo " Copying source image"
  cp "$SOURCE/$VER-raspbian-stretch-lite.img" "$DEST/ClusterHAT-$VER-lite-$REV-controller.img"
  LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-controller.img`
  sleep 5
  kpartx -av $LOOP
  sleep 5

  mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT
  mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot

  # Get any updates / install and remove pacakges
  chroot $MNT apt-get update
  chroot $MNT /bin/bash -c 'APT_LISTCHANGES_FRONTEND=none apt-get -y dist-upgrade'
  chroot $MNT apt-get -y install bridge-utils wiringpi screen minicom python-smbus

  # Disable APIPA addresses on ethpiX and eth0
  echo -e "# ClusterHAT\ndenyinterfaces eth0 ethpi1 ethpi2 ethpi3 ethpi4" >> $MNT/etc/dhcpcd.conf

  # Ensure we're going to do a text boot
  chroot $MNT systemctl set-default multi-user.target

  # Enable Cluster HAT init
  sed -i "s#^exit 0#/sbin/clusterhat init\nexit 0#" $MNT/etc/rc.local

  # Enable uart
  lua - enable_uart 1 $MNT/boot/config.txt <<EOF > $MNT/boot/config.txt.bak
  local key=assert(arg[1])
  local value=assert(arg[2])
  local fn=assert(arg[3])
  local file=assert(io.open(fn))
  local made_change=false
  for line in file:lines() do
    if line:match("^#?%s*"..key.."=.*$") then
      line=key.."="..value
      made_change=true
    end
    print(line)
  end

  if not made_change then
    print(key.."="..value)
  end
EOF
  mv $MNT/boot/config.txt.bak $MNT/boot/config.txt

  # Enable I2C (used for I/O expander on Cluster HAT v2.x)
  lua - dtparam=i2c_arm on $MNT/boot/config.txt <<EOF > $MNT/boot/config.txt.bak
  local key=assert(arg[1])
  local value=assert(arg[2])
  local fn=assert(arg[3])
  local file=assert(io.open(fn))
  local made_change=false
  for line in file:lines() do
    if line:match("^#?%s*"..key.."=.*$") then
      line=key.."="..value
      made_change=true
    end
    print(line)
  end

  if not made_change then
    print(key.."="..value)
  end
EOF
  mv $MNT/boot/config.txt.bak $MNT/boot/config.txt
  if [ -f $MNT/etc/modprobe.d/raspi-blacklist.conf ];then
   sed $MNT/etc/modprobe.d/raspi-blacklist.conf -i -e "s/^\(blacklist[[:space:]]*i2c[-_]bcm2708\)/#\1/"
  fi
  sed $MNT/etc/modules -i -e "s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"

  if ! grep -q "^i2c[-_]dev" $MNT/etc/modules; then
   printf "i2c-dev\n" >> $MNT/etc/modules
  fi

  # Change the hostname to "controller"
  sed -i "s#^127.0.1.1.*#127.0.1.1\tcontroller#g" $MNT/etc/hosts
  echo "controller" > $MNT/etc/hostname

  # Extract files
  (tar --exclude=.git -zcC ../files/ -f - .) | (chroot $MNT tar -zxC /)

  # Copy network config files
  cp -f $MNT/$CONFIGDIR/interfaces.c $MNT/etc/network/interfaces

  # Disable the auto filesystem resize
  sed -i 's/ quiet init=.*$//' $MNT/boot/cmdline.txt

  # Setup config.txt file
  C=`grep -c "dtoverlay=dwc2" $MNT/boot/config.txt`
  if [ $C -eq 0  ];then
   echo -e "# Load overlay to allow USB Gadget devices\n#dtoverlay=dwc2" >> $MNT/boot/config.txt
  fi

  PARTUUID=`sed "s/.*PARTUUID=\(.*\) rootfstype.*/\1/" $MNT/boot/cmdline.txt`

  rm -f $MNT/etc/ssh/*key*
  chroot $MNT apt-get -y autoremove --purge
  chroot $MNT apt-get clean

  umount $MNT/boot
  umount $MNT

  kpartx -dv $LOOP
  losetup -d $LOOP

  if [ -f $DEST/ClusterHAT-$VER-lite-$REV-p1.img ];then
   echo "Skipping P1 (file exists)"
  else
   echo "Creating P1"
   cp $DEST/ClusterHAT-$VER-lite-$REV-controller.img $DEST/ClusterHAT-$VER-lite-$REV-p1.img
   LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-p1.img`
   sleep 5
   kpartx -av $LOOP
   sleep 5
   mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT
   mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot
   echo -n "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=$PARTUUID rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/sbin/reconfig-clusterhat p1" > $MNT/boot/cmdline.txt
   umount $MNT/boot
   umount $MNT
   kpartx -dv $LOOP
   losetup -d $LOOP
  fi

  if [ -f $DEST/ClusterHAT-$VER-lite-$REV-p2.img ];then
   echo "Skipping P2 (file exists)"
  else
   echo "Creating P2"
   cp $DEST/ClusterHAT-$VER-lite-$REV-controller.img $DEST/ClusterHAT-$VER-lite-$REV-p2.img
   LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-p2.img`
   sleep 5
   kpartx -av $LOOP
   sleep 5
   mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT
   mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot
   echo -n "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=$PARTUUID rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/sbin/reconfig-clusterhat p2" > $MNT/boot/cmdline.txt
   umount $MNT/boot
   umount $MNT
   kpartx -dv $LOOP
   losetup -d $LOOP
  fi

  if [ -f $DEST/ClusterHAT-$VER-lite-$REV-p3.img ];then
   echo "Skipping P3 (file exists)"
  else
   echo "Creating P3"
   cp $DEST/ClusterHAT-$VER-lite-$REV-controller.img $DEST/ClusterHAT-$VER-lite-$REV-p3.img
   LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-p3.img`
   sleep 5
   kpartx -av $LOOP
   sleep 5
   mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT
   mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot
   echo -n "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=$PARTUUID rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/sbin/reconfig-clusterhat p3" > $MNT/boot/cmdline.txt
   umount $MNT/boot
   umount $MNT
   kpartx -dv $LOOP
   losetup -d $LOOP
  fi

  if [ -f $DEST/ClusterHAT-$VER-lite-$REV-p4.img ];then
   echo "Skipping P4 (file exists)"
   else
   echo "Creating P4"
   cp $DEST/ClusterHAT-$VER-lite-$REV-controller.img $DEST/ClusterHAT-$VER-lite-$REV-p4.img
   LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-p4.img`
   sleep 5
   kpartx -av $LOOP
   sleep 5
   mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT
   mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot
   echo -n "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=$PARTUUID rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/sbin/reconfig-clusterhat p4" > $MNT/boot/cmdline.txt
   umount $MNT/boot
   umount $MNT
   kpartx -dv $LOOP
   losetup -d $LOOP
  fi

 fi # End check dest image exists
fi # End of build lite

## END Build LITE

if [ "$DESKTOP" = "y" ];then
 if [ -f "$DEST/ClusterHAT-$VER-$REV-controller.img" ];then
  echo "Skipping DESKTOP build"
  echo " $DEST/ClusterHAT-$VER-$REV-controller.img exists"
 else
  echo "Building DESKTOP"
  echo " Copying source image"
  cp "$SOURCE/$VER-raspbian-stretch.img" "$DEST/ClusterHAT-$VER-$REV-controller.img"
  LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-$REV-controller.img`
  sleep 5
  kpartx -av $LOOP
  sleep 5

  mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT
  mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot

  # Get any updates / install and remove pacakges
  chroot $MNT apt-get update
  chroot $MNT /bin/bash -c 'APT_LISTCHANGES_FRONTEND=none apt-get -y dist-upgrade'
  chroot $MNT apt-get -y install bridge-utils wiringpi screen minicom python-smbus
  chroot $MNT apt-get -y purge wolfram-engine 

  # Disable APIPA addresses on ethpiX and eth0
  echo -e "# ClusterHAT\ndenyinterfaces eth0 ethpi1 ethpi2 ethpi3 ethpi4" >> $MNT/etc/dhcpcd.conf

  # Enable Cluster HAT init
  sed -i "s#^exit 0#/sbin/clusterhat init\nexit 0#" $MNT/etc/rc.local

  # Enable uart
  lua - enable_uart 1 $MNT/boot/config.txt <<EOF > $MNT/boot/config.txt.bak
  local key=assert(arg[1])
  local value=assert(arg[2])
  local fn=assert(arg[3])
  local file=assert(io.open(fn))
  local made_change=false
  for line in file:lines() do
    if line:match("^#?%s*"..key.."=.*$") then
      line=key.."="..value
      made_change=true
    end
    print(line)
  end

  if not made_change then
    print(key.."="..value)
  end
EOF
  mv $MNT/boot/config.txt.bak $MNT/boot/config.txt

  # Enable I2C (used for I/O expander on Cluster HAT v2.x)
  lua - dtparam=i2c_arm on $MNT/boot/config.txt <<EOF > $MNT/boot/config.txt.bak
  local key=assert(arg[1])
  local value=assert(arg[2])
  local fn=assert(arg[3])
  local file=assert(io.open(fn))
  local made_change=false
  for line in file:lines() do
    if line:match("^#?%s*"..key.."=.*$") then
      line=key.."="..value
      made_change=true
    end
    print(line)
  end

  if not made_change then
    print(key.."="..value)
  end
EOF
  mv $MNT/boot/config.txt.bak $MNT/boot/config.txt
  sed $MNT/etc/modprobe.d/raspi-blacklist.conf -i -e "s/^\(blacklist[[:space:]]*i2c[-_]bcm2708\)/#\1/"
  sed $MNT/etc/modules -i -e "s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"

  if ! grep -q "^i2c[-_]dev" $MNT/etc/modules; then
   printf "i2c-dev\n" >> $MNT/etc/modules
  fi

  # Change the hostname to "controller"
  sed -i "s#^127.0.1.1.*#127.0.1.1\tcontroller#g" $MNT/etc/hosts
  echo "controller" > $MNT/etc/hostname

  # Extract files
   (tar -zcC../files/ -f - .) | (chroot $MNT tar -zxC /)

  # Copy network config files
  cp -f $MNT/$CONFIGDIR/interfaces.c $MNT/etc/network/interfaces

  # Disable the auto filesystem resize
  sed -i 's/ quiet init=.*$//' $MNT/boot/cmdline.txt

  # Setup config.txt file
  C=`grep -c "dtoverlay=dwc2" $MNT/boot/config.txt`
  if [ $C -eq 0  ];then
   echo -e "# Load overlay to allow USB Gadget devices\n#dtoverlay=dwc2" >> $MNT/boot/config.txt
  fi

  PARTUUID=`sed "s/.*PARTUUID=\(.*\) rootfstype.*/\1/" $MNT/boot/cmdline.txt`

  rm -f $MNT/etc/ssh/*key*
  chroot $MNT apt-get -y autoremove --purge
  chroot $MNT apt-get clean

  umount $MNT/boot
  umount $MNT

 fi # End check dest image exists
fi # End of build desktop
