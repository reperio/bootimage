#!/bin/ash
#
# This script builds the initramfs for breakin in the Docker
# container.
#

[ -d /mnt/out ] || {
	echo "Output volume not mounted"
	echo "Specify '-v' like so:"
	printf "\tdocker run -v \"\${PWD}\":/mnt/out -it ..."
	exit 255
}

# Clone and build the latest breakin master
cd /
git clone https://github.com/reperio/breakin.git || exit 1
cd breakin

if [ $(find /usr/lib -name libtinfo.so* 2>/dev/null | wc -l) -eq 0 ]
then
	sed -i -e s/-ltinfo//g Makefile
fi

cat /mce.sh > scripts/tests/mcelog
chmod 0750 scripts/tests/mcelog
sed -i -e '4irm -f /tmp/.syslog_pos' scripts/stop.sh
make clean all || exit 2
make install   || exit 3

# Make the initramfs
cp /breakin.* /tmp/
apk info -L \
	ncurses-libs libcurl brotli-libs nghttp2-libs libssl zlib openmpi \
	openblas ipmitool readline rasdaemon dmidecode sqlite-libs libsmartcols \
	dropbear-ssh \
| grep -v 'contains:' | grep . >> /tmp/breakin.files

mkinitfs -P /tmp -c /mkinitfs.conf -i /init -o /mnt/out/initramfs \
$(ls -la /lib/modules | tail -1 | awk '{print $NF}') || exit 4

# Copy out the kernel and initramfs
cp /boot/vmlinuz-lts /mnt/out/vmlinux
chmod 0666 /mnt/out/initramfs /mnt/out/vmlinux
rm -f /tmp/breakin.* breakin

# Make the iso
mkdir -p /iso/boot/grub
cp /boot/vmlinuz-lts /iso/vmlinuz
cp /mnt/out/initramfs /iso/initramfs
cp /mnt/out/grub.cfg /iso/boot/grub/
grub-mkrescue -o /mnt/out/bootimg.iso /iso
chmod 0666 /mnt/out/bootimg.iso
rm -rf /iso

