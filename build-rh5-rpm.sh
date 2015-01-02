#!/bin/bash

# Import VERSION
. ./configure.in

. ./functions

TOPDIR=${PWD}
export TOPDIR
SRCDIR=${PWD}/src
export SRCDIR
STAGEDIR=${PWD}/stage/initrd-${VERSION}
export STAGEDIR
CDSTAGEDIR=${PWD}/stage/iso-${VERSION}
export CDSTAGEDIR
TARSTAGEDIR=${PWD}/stage/bootimage-${VERSION}
export TARSTAGEDIR
PATCHDIR=${PWD}/patches
export PATCHDIR
KERNELDIR=${PWD}/kernel/linux-${KERNELVER}
export KERNELDIR
KERNELBIN=${PWD}/kernel/linux-${KERNELVER}/arch/${ARCH}/boot/bzImage
export KERNELBIN
LOGDIR=${PWD}/log
export LOGDIR

##
# MAKE RPM FOR FOSS EDITION
#

echo -en "Creating RPM dist/bootimage-${VERSION}.rpm"
cd ${TOPDIR}/dist
rpmbuild -bb --define "_rpmdir ${TOPDIR}/dist/rhel5" bootimage.spec
if [ $? != 0 ]; then
  echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
  exit 1
fi
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

##
# SUCCESS
#

echo -e "${ANSI_GREEN}BUILD COMPLETED SUCESSFULLY${ANSI_DONE}"
exit 0

# vim:ts=2:sw=2:expandtab
