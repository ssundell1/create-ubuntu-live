TARGET="chroot"
TARGET="`pwd`/$TARGET"

rm -rf image
rm TEST_IMAGE.iso

echo "Checking prerequisites..."
sudo apt-get --yes install syslinux squashfs-tools genisoimage

echo "Working on $TARGET"

if [ ! -d $TARGET ]
then
    mkdir $TARGET
    debootstrap --arch amd64 jammy $TARGET
fi

sudo cp /etc/hosts chroot/etc/hosts
sudo cp /etc/resolv.conf chroot/etc/resolv.conf
sudo cp /etc/apt/sources.list chroot/etc/apt/sources.list

sudo cp ./run_inside_chroot.sh $TARGET
sudo chroot chroot /bin/bash run_inside_chroot.sh
rm $TARGET/run_inside_chroot.sh

# Umount
umount chroot/proc
umount chroot/sys
umount chroot/dev/pts

if [ ! -d image ]
then
    mkdir -p image/casper
    mkdir image/isolinux
    mkdir image/install
fi

cp chroot/boot/vmlinuz-5.15.**-**-generic image/casper/vmlinuz
cp chroot/boot/initrd.img-5.15.**-**-generic image/casper/initrd.gz

cp /usr/lib/ISOLINUX/isolinux.bin image/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 image/isolinux/ # for syslinux 5.00 and newer
cp template/isolinux/isolinux.cfg image/isolinux/

cp template/etc/systemd/system/*.service chroot/etc/systemd/system/

cp /boot/memtest86+.bin image/install/memtest

sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE
do
        sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done

mksquashfs chroot image/casper/filesystem.squashfs
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

cd image
sudo mkisofs -r -V "TEST_IMAGE" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../TEST_IMAGE.iso .
cd ..