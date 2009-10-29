#!/bin/bash

# Import VERSION
. ./configure.in
. ./functions

mkdir ${STAGEDIR}/dev
mkdir ${STAGEDIR}/dev/pts
mknod -m 0660 ${STAGEDIR}/dev/console c 5 1
mknod -m 0660 ${STAGEDIR}/dev/tty c 5 0
mknod -m 0660 ${STAGEDIR}/dev/tty0 c 4 0
mknod -m 0660 ${STAGEDIR}/dev/tty1 c 4 1
mknod -m 0660 ${STAGEDIR}/dev/tty2 c 4 2
mknod -m 0660 ${STAGEDIR}/dev/tty3 c 4 3
mknod -m 0660 ${STAGEDIR}/dev/tty4 c 4 4
mknod -m 0660 ${STAGEDIR}/dev/tty5 c 4 5
mknod -m 0660 ${STAGEDIR}/dev/tty6 c 4 6
mknod ${STAGEDIR}/dev/null c 1 3

##
# COMPRESS INITRD FOR FOSS EDITION
#

echo -en "Compressing initramfs to dist/initrd-v${VERSION}.cpio.lzma"
cd ${STAGEDIR}
find . | cpio -o -H newc | lzma > ${TOPDIR}/dist/initrd-v${VERSION}.cpio.lzma
if [ $? != 0 ]; then
  echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
  exit 1
fi
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"
