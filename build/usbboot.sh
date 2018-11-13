#!/bin/bash -x

source ./config.sh

if [ $# -ne 1 ]; then
 echo "Usage: $0 <version>"
 echo " Where version is 2017-09-07 in ClusterHAT-2017-09-07-1-controller.img"
 echo " Builds lite & desktop images for usbboot"
 echo " SOURCE=$SOURCE (see config.sh)"
 echo " DEST=$DEST (source of ClusterHAT images)"
 echo " OUTPUTFILE=$DEST/ClusterHAT-$VER-lite-$REV-usbboot.img"
 echo ""
 exit
fi

VER=$1

# Detect which source files we have (lite/desktop)
FOUND=0
if [ -f "$DEST/ClusterHAT-$VER-lite-$REV-controller.img" ];then
 LITE=y
 FOUND=1
fi
if [ -f "$DEST/ClusterHAT-$VER-$REV-controller.img" ];then
 DESKTOP=y
 FOUND=1
 echo "Desktop build TODO"
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
 if [ -f "$DEST/ClusterHAT-$VER-lite-$REV-usbboot.img" ];then
  echo "Skipping LITE build"
  echo " $DEST/ClusterHAT-$VER-lite-$REV-usbboot.img exists"
 else
  # Create image file
  dd if=/dev/zero bs=500M seek=15 count=0 of=$DEST/ClusterHAT-$VER-lite-$REV-usbboot.img

  # Create partition table
  parted $DEST/ClusterHAT-$VER-lite-$REV-usbboot.img --script -- mklabel msdos
  parted $DEST/ClusterHAT-$VER-lite-$REV-usbboot.img --script -- mkpart primary fat32 0% 64M
  parted $DEST/ClusterHAT-$VER-lite-$REV-usbboot.img --script -- mkpart primary 64M 100%

  # Create devices for destination image partitions
  LOOP=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-usbboot.img`
  sleep 5
  kpartx -av $LOOP
  sleep 5

  # Create filesystems on image partitions
  mkdosfs -F 32 -n BOOT -v `echo $LOOP|sed s#dev#dev/mapper#`p1
  mkfs.ext4 -F -m 1 -L ROOT `echo $LOOP|sed s#dev#dev/mapper#`p2

  # Mount destination filesystems
  mount `echo $LOOP|sed s#dev#dev/mapper#`p2 $MNT 
  mkdir $MNT/boot
  mount `echo $LOOP|sed s#dev#dev/mapper#`p1 $MNT/boot


  # Create devices for source image partitions
  LOOP2=`losetup -f --show $DEST/ClusterHAT-$VER-lite-$REV-controller.img`
  sleep 5
  kpartx -av $LOOP2
  sleep 5

  # Mount source filesystems
  mount -o ro `echo $LOOP2|sed s#dev#dev/mapper#`p2 $MNT2
  mount -o ro `echo $LOOP2|sed s#dev#dev/mapper#`p1 $MNT2/boot

  # Copy controller filesystem over to new image
  (tar -cC $MNT2 .)|(tar -C $MNT -x)

  # Fix fstab/cmdline on the controller
  # Get partial PARTUUID
  LOOPN=`echo $LOOP|sed "s#.*/##"`
  PARTUUID=`blkid /dev/mapper/${LOOPN}p1|sed "s/ /\n/g"|grep PART|sed 's/.*"\(.*\)-..".*/\1/'`
  sed -i "s#root=PARTUUID=.*-02 #root=PARTUUID=$PARTUUID-02 #" $MNT/boot/cmdline.txt
  sed -i "s#^PARTUUID=.*-#PARTUUID=$PARTUUID-#" $MNT/etc/fstab

  # expand filesystem
  sed -ie 's#$# init=/usr/lib/raspi-config/init_resize.sh#' $MNT/boot/cmdline.txt

  # Extract files (ensure we're running the latest version)
  (tar --exclude=.git -zcC ../files/ -f - .) | (chroot $MNT tar -zxC /)

  # Get any updates / install and remove packages
  chroot $MNT /bin/bash -c 'apt-get update'
  chroot $MNT /bin/bash -c 'DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade'
  chroot $MNT /bin/bash -c 'apt-get -y install rpiboot bridge-utils wiringpi screen minicom git libusb-1.0-0-dev kpartx nfs-kernel-server'

  # Enable VLAN supprot
  echo 8021q >> $MNT/etc/modules

  # Copy over a "blank" interfaces file
  cp -f "$MNT/usr/share/clusterhat/interfaces.p" $MNT/etc/network/interfaces

  # Change denyinterface (original changes might be wiped out from dist-upgrade above)
  # DHCPCD no longer runs if /etc/network/interfaces has config but we've using a file in /etc/network/interfaces.d/
  C=`grep -c denyinterfaces $MNT/etc/dhcpcd.conf`
  if [ "$C" -eq "0" ];then
   # Option doesn't exist so add it all
   echo -e "# ClusterHAT\ndenyinterfaces eth0 ethpi* ethpi*.10 brint" >> $MNT/etc/dhcpcd.conf
  else
   sed -i "s#denyinterface.*#denyinterfaces eth0 ethpi* ethpi*.10 brint#" $MNT/etc/dhcpcd.conf
  fi

  sed -i 's#"net", #"net", SUBSYSTEMS=="usb", #' $MNT/etc/udev/rules.d/90-clusterhat.rules

  # Setup network
  echo "# Internal network (untagged on Pi Zeros)
auto brint brext
iface brint inet static
	bridge_ports none
	address 172.19.180.254
	netmask 255.255.255.0
	bridge_stp off
	bridge_waitport 0
	bridge_fd 0

# External network (VLAN10 on Pi Zeros)
iface brext inet manual
	bridge_ports eth0
	bridge_stp off
	bridge_waitport 0
	bridge_fd 0
	post-up /sbin/copyMAC eth0 brext
" > $MNT/etc/network/interfaces.d/clusterhat

  I=0
  while [ $I -lt 256 ];do
    echo "# Internal network untagged
allow-hotplug ethpi$I
iface ethpi$I inet manual
	pre-up ifup brint
	pre-up brctl addif brint ethpi$I
	up ifconfig ethpi$I up
	post-up ip link add link ethpi$I name ethpi$I.10 type vlan id 10

# External network (VLAN 10)
allow-hotplug ethpi$I.10
iface ethpi$I.10 inet manual
	pre-up brctl addif brext ethpi$I.10"
    echo
    let I=$I+1
  done >> $MNT/etc/network/interfaces.d/clusterhat

  mkdir -p $MNT/var/lib/clusterhat/nfs/{p1,p2,p3,p4}
  mkdir $MNT/var/lib/clusterhat/boot

  tar -cC $MNT2 .|tee >(tar -xC $MNT/var/lib/clusterhat/nfs/p1/) >(tar -xC $MNT/var/lib/clusterhat/nfs/p2/) >(tar -xC $MNT/var/lib/clusterhat/nfs/p3/) | tar -xC $MNT/var/lib/clusterhat/nfs/p4/

  for I in 1 2 3 4 ; do
    chroot $MNT/var/lib/clusterhat/nfs/p$I/ /bin/bash -c 'apt-get update'
    chroot $MNT/var/lib/clusterhat/nfs/p$I/ /bin/bash -c 'DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade'
    cp "$MNT/usr/share/clusterhat/cmdline.p$I" $MNT/var/lib/clusterhat/nfs/p$I/boot/cmdline.txt
    cp -f "$MNT/usr/share/clusterhat/interfaces.p" $MNT/var/lib/clusterhat/nfs/p$I/etc/network/interfaces
    cp -f "$MNT/usr/share/clusterhat/issue.p" $MNT/var/lib/clusterhat/nfs/p$I/etc/issue
    C=`grep -c denyinterfaces $MNT/var/lib/clusterhat/nfs/p$I/etc/dhcpcd.conf`
    if [ "$C" -eq "0" ];then
     # Option doesn't exist so add it all
     echo -e "# ClusterHAT\ndenyinterfaces usb0" >> $MNT/var/lib/clusterhat/nfs/p$I/etc/dhcpcd.conf
    else
     sed -i "s#^denyinterfaces.*#denyinterfaces usb0#" $MNT/var/lib/clusterhat/nfs/p$I/etc/dhcpcd.conf
    fi
    sed -i "s#^denyinterfaces.*#denyinterfaces usb0#" $MNT/var/lib/clusterhat/nfs/p$I/etc/dhcpcd.conf
    echo -e "\nauto usb0.10\nallow-hotplug usb0.10\n\niface usb0.10 inet manual\n" > $MNT/var/lib/clusterhat/nfs/p$I/etc/network/interfaces.d/clusterhat
    sed -i "s/^PARTUUID.*//" $MNT/var/lib/clusterhat/nfs/p$I/etc/fstab
    sed -i "s#^127.0.1.1.*#127.0.1.1\tp$I#g" $MNT/var/lib/clusterhat/nfs/p$I/etc/hosts
    sed -i "s/^#dtoverlay=dwc2$/dtoverlay=dwc2/" $MNT/var/lib/clusterhat/nfs/p$I/boot/config.txt
    echo "p$I" > $MNT/var/lib/clusterhat/nfs/p$I/etc/hostname
    sed -i "s#root=.* rootfstype=ext4#root=/dev/nfs nfsroot=172.19.180.254:/var/lib/clusterhat/nfs/p$I rw ip=172.19.180.$I:172.19.180.254::255.255.255.0:p$I:usb0:static#" $MNT/var/lib/clusterhat/nfs/p$I/boot/cmdline.txt
    sed -i "s#MODULES=most#MODULES=netboot#" $MNT/var/lib/clusterhat/nfs/p$I/etc/initramfs-tools/initramfs.conf
    echo "BOOT=nfs" >> $MNT/var/lib/clusterhat/nfs/p$I/etc/initramfs-tools/initramfs.conf
    echo -e "dwc2\ng_cdc\nuio_pdrv_genirq\nuio\nusb_f_acm\nu_serial\nusb_f_ecm\nu_ether\nlibcomposite\nudc_core\nipv6\n" >> $MNT/var/lib/clusterhat/nfs/p$I/etc/initramfs-tools/modules
# Don't build for CM3 yet as the kernel is missing support
#    for V in `(cd $MNT/var/lib/clusterhat/nfs/p$I/lib/modules/;ls|grep v7)`; do
#     chroot $MNT/var/lib/clusterhat/nfs/p$I/ /bin/bash -c "mkinitramfs -o /boot/initramfs7.img $V"
#    done
    # Pi Zero / CM1
    for V in `(cd $MNT/var/lib/clusterhat/nfs/p$I/lib/modules/;ls|grep -v v7)`; do
     chroot $MNT/var/lib/clusterhat/nfs/p$I/ /bin/bash -c "mkinitramfs -o /boot/initramfs.img $V"
    done
    echo -e "\n[pi0]\ninitramfs initramfs.img\n[pi1]\ninitramfs initramfs.img\n[pi3]\ninitramfs initramfs7.img\n[all]\n" >> $MNT/var/lib/clusterhat/nfs/p$I/boot/config.txt
    echo "/var/lib/clusterhat/nfs/p$I 172.19.180.$I(rw,sync,no_subtree_check,no_root_squash)" >> $MNT/etc/exports
    touch $MNT/var/lib/clusterhat/nfs/p$I/boot/ssh
    chroot $MNT/var/lib/clusterhat/nfs/p$I/ /bin/bash -c "echo 'pi:$PASSWORD' | chpasswd"
    # Enable serial console on Pi Zeros
    lua - enable_uart 1 $MNT/var/lib/clusterhat/nfs/p$I/boot/config.txt <<EOF > $MNT/var/lib/clusterhat/nfs/p$I/boot/config.txt.bak
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
    mv $MNT/var/lib/clusterhat/nfs/p$I/boot/config.txt.bak $MNT/var/lib/clusterhat/nfs/p$I/boot/config.txt
  done

  # Enable serial console (on controller)
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

  # Setup links for boot
  (cd $MNT/var/lib/clusterhat/;cp -r nfs/p1/boot .)
  (cd $MNT/var/lib/clusterhat/;ln -s ../nfs/p4/boot/ boot/1-1.2.1)
  (cd $MNT/var/lib/clusterhat/;ln -s ../nfs/p3/boot/ boot/1-1.2.2)
  (cd $MNT/var/lib/clusterhat/;ln -s ../nfs/p2/boot/ boot/1-1.2.3)
  (cd $MNT/var/lib/clusterhat/;ln -s ../nfs/p1/boot/ boot/1-1.2.4)
  

  # Enable NFS
  chroot $MNT systemctl enable nfs-kernel-server

  # Set custom password if PASSWORD has been set to something other than an empty string
  chroot $MNT /bin/bash -c "echo 'pi:$PASSWORD' | chpasswd"

  # Start rpiboot in screen session
  sed -i "s#^exit 0#/usr/bin/screen -S rpiboot -d -m /usr/bin/rpiboot -m 2000 -d /var/lib/clusterhat/boot/ -o -l -v\n\nexit 0#" $MNT/etc/rc.local

  # Cleanup
  umount $MNT/boot
  umount $MNT 
  umount $MNT2/boot
  umount $MNT2
  kpartx -dv $LOOP
  losetup -d $LOOP
  kpartx -dv $LOOP2
  losetup -d $LOOP2

  

  fi # End check dest image exists
  echo "Lite build completed"
fi # End of build lite
