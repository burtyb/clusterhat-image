#!/bin/bash
#
# (c) 2019 Chris Burton
#
# Setup USB Gadget devices
#
# Reads command line "clusterctrl=X" argument from /proc/cmdline and configures
#
# Options for X
#
# clusterctrl=c = "controller" with Bridged Ethernet 
# clusterctrl=cnat = "cnat" with NAT for WiFi or Ethernet
# clusterctrl=pX = "PX" where X can be 0 to 255
#
# Configures the following Composite USB Gadgets
# Ethernet "usb0" - External Network Interface
# Ethernet "usb1" - Internal Network Interface

modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir g && cd g

echo 0x3171 > idVendor  # 8086 Consultancy
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB 2.0

echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

mkdir -p strings/0x809
echo "20190327" > strings/0x809/serialnumber
echo "8086 Consultancy"        > strings/0x809/manufacturer
echo "ClusterCTRL"   > strings/0x809/product

mkdir -p functions/acm.usb0    # serial
mkdir -p functions/acm.usb1
mkdir -p functions/rndis.usb0  # network

printf "00:22:82:ff:fe:%x" > functions/rndis.usb0/host_addr
printf "00:22:82:ff:ff:%x" > functions/rndis.usb0/dev_addr

mkdir -p configs/c.1
echo 1 > configs/c.1/MaxPower
ln -s functions/rndis.usb0 configs/c.1/
ln -s functions/acm.usb0   configs/c.1/
ln -s functions/acm.usb1   configs/c.1/

# OS descriptors
echo 1       > os_desc/use
echo 0xcd    > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

echo RNDIS   > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

ln -s configs/c.1 os_desc

udevadm settle -t 5 || :
ls /sys/class/udc/ > UDC
