#!/bin/bash

# Import VERSION
. ./configure.in
. ./functions

mkdir ${STAGEDIR}/dev
mkdir ${STAGEDIR}/dev/pts
mknod -m 0600 ${STAGEDIR}/dev/console c 5 1
mknod ${STAGEDIR}/dev/null c 1 3

##
# COMPRESS INITRD FOR FOSS EDITION
#

echo -en "Compressing initramfs to dist/initrd-v${VERSION}.cpio.gz"
cd ${STAGEDIR}
find . | cpio -o -H newc | gzip > ${TOPDIR}/dist/initrd-v${VERSION}.cpio.gz
if [ $? != 0 ]; then
  echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
  exit 1
fi
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"
