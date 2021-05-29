#!/bin/bash

NET=${BASH_SOURCE%/*}"/../../files/usr/share/clusterctrl/interfaces"

# Creates ClusterCTRL /e/n/i.d/clusterctrl for cnat and cbridge

echo '
#
# Interface definitions for Cluster CTRL (bridged controller)
#

auto brint br0

# Interfaces bridged to brint (internal network)
# - usbboot - Pi node "usb0.10" (VLAN 10 for NFSROOT)
# - SD boot - unused

iface brint inet static
        bridge_ports none
        address 172.19.180.254
        netmask 255.255.255.0
        bridge_stp off
        bridge_waitport 0
        bridge_fd 0

# Interfaces bridged to br0 (external network)
# - usbboot - Pi node "usb0" (untagged)
# - SD boot - Pi node "usb0" (untagged)

iface br0 inet manual
        bridge_ports eth0
        bridge_stp off
        bridge_waitport 0
        bridge_fd 0
        post-up /usr/sbin/copyMAC eth0 br0

# USB Gadget Ethernet node (controller) interfaces

' > $NET


for ((P=1;P<=252;P++));do
 echo "## Pi node P${P}"  >> $NET
 # SD boot
 echo "# SD boot
allow-hotplug ethpi${P}
iface ethpi${P} inet manual
        pre-up ifup br0
        pre-up brctl addif br0 ethpi${P}
	up ip link set dev ethpi${P} up
" >> $NET
 # usbboot
 echo "# usbboot
# Internal network (VLAN 10)
allow-hotplug ethupi${P}.10
iface ethupi${P}.10 inet manual
        pre-up ifup brint
        pre-up brctl addif brint ethupi${P}.10

# External network (untagged)
allow-hotplug ethupi${P}
iface ethupi${P} inet manual
	pre-up ifup br0
	pre-up brctl addif br0 ethupi${P}
	up ip link set dev ethupi${P} up
	post-up ip link add link ethupi${P} name ethupi${P}.10 type vlan id 10
" >> $NET

done

rm -f "${NET}.cnat"
rm -f "${NET}.cbridge"
cp "$NET" "${NET}.cnat"
mv "$NET" "${NET}.cbridge"
sed -i "s#bridge_ports eth0#bridge_ports none#" "${NET}.cnat"
