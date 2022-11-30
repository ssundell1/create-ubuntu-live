#!/bin/bash
echo "INSIDE CHROOT"

# Mount
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

apt-get update
apt-get install --yes dbus
dbus-uuidgen > /var/lib/dbus/machine-id

apt-get --yes upgrade

apt-get install --yes ubuntu-standard casper initramfs-tools
apt-get install --yes discover laptop-detect os-prober
apt-get install --yes linux-generic

# Clean up machine-id
rm /var/lib/dbus/machine-id

# Clean up old kernels
ls /boot/vmlinuz-5.15.**-**-generic > list.txt
sum=$(cat list.txt | grep '[^ ]' | wc -l)
if [ $sum -gt 1 ]; then
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
fi
rm list.txt

apt-get autoremove
apt-get clean
rm -rf /tmp/*
rm /etc/resolv.conf

exit