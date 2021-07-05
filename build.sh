#!/usr/bin/env bash
CHECKRA1N_I486_URL="https://assets.checkra.in/downloads/linux/cli/i486/77779d897bf06021824de50f08497a76878c6d9e35db7a9c82545506ceae217e/checkra1n"
BOOTLOADER="boot.S"
OUTPUT="boot.img"
KERN="./linux/arch/x86/boot/bzImage"
RD="./initramfs.cpio.zst"
export CFLAGS="-m32 -march=i486"
export CXXFLAGS="-m32 -march=i486"

# kernel
if [ ! -f "./linux/.build_complete" ]; then
cp .config linux
cd linux
make -j$(nproc) && touch .build_complete
cd ..
fi
# initramfs
rm -rf rootfs
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
 # size of kern + ramdisk
K_SZ=`stat -c %s $KERN`
R_SZ=`stat -c %s $RD`

 # padding to make it up to a sector
K_PAD=$((512 - $K_SZ % 512))
R_PAD=$((512 - $R_SZ % 512))

nasm -o $OUTPUT -D initRdSizeDef=$R_SZ $BOOTLOADER
# image
cat $KERN >> $OUTPUT
if [[ $K_PAD -lt 512 ]]; then
    dd if=/dev/zero bs=1 count=$K_PAD >> $OUTPUT
fi

cat $RD >> $OUTPUT
if [[ $R_PAD -lt 512 ]]; then
    dd if=/dev/zero bs=1 count=$R_PAD >> $OUTPUT
fi

TOTAL=`stat -c %s $OUTPUT`

echo "$OUTPUT is ready. ($TOTAL)"
