#!/usr/bin/env bash
CHECKRA1N_I486_URL="https://assets.checkra.in/downloads/linux/cli/i486/77779d897bf06021824de50f08497a76878c6d9e35db7a9c82545506ceae217e/checkra1n"
SYSLINUX="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz"
KERN="./linux/arch/x86/boot/bzImage"
RD="./initramfs.cpio.zst"
VERSION=1.0
export CFLAGS="-m32 -march=i486"
export CXXFLAGS="-m32 -march=i486"

rm -rf rootfs syslinux-*/ CD_Root
# kernel
if [ ! -f "./linux/.build_complete" ]; then
cp .config linux
cd linux
make -j$(nproc) && touch .build_complete
cd ..
fi
# initramfs
 # base structure
mkdir -p rootfs/usr/{bin,sbin}
mkdir -p rootfs/{dev,sys,proc,tmp,var,lib}
ln -s /tmp rootfs/var/tmp
ln -s /usr/bin rootfs/bin
ln -s /usr/sbin rootfs/sbin
 # copy resources
cp busybox rootfs/usr/bin
wget -O rootfs/usr/bin/checkra1n $CHECKRA1N_I486_URL
# cp checkra1n rootfs/usr/bin/checkra1n
cp init rootfs
cp ld-musl-i386.so.1 rootfs/lib
chmod +x rootfs/usr/bin/checkra1n
 # device nodes
cp -dpR /dev/tty[0-6] rootfs/dev
cp -dpR /dev/{tty,console,null,zero,full} rootfs/dev
 # pack
cd rootfs
find . | fakeroot cpio -oH newc | zstd -c19 > ../initramfs.cpio.zst
cd ..
 # bootloader
wget -O- $SYSLINUX | tar -xJ
mkdir -p CD_Root/{isolinux,images,kernel}
cp syslinux-*/bios/core/isolinux.bin CD_Root/isolinux
cp syslinux-*/bios/com32/elflink/ldlinux/ldlinux.c32 CD_Root/isolinux
cp syslinux-*/bios/memdisk/memdisk CD_Root/kernel
cp $KERN CD_Root/vmlinuz
cp $RD CD_Root/rfs.zst
# boot config
cat << EOF > isolinux.cfg
SAY Tinyn1x-$VERSION
DEFAULT tinyn1x
LABEL tinyn1x
LINUX /vmlinuz
INITRD /rfs.zst
EOF
cp isolinux.cfg CD_Root/isolinux
# make .iso
mkisofs -o boot.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table CD_Root
