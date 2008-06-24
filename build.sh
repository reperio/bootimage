#!/bin/sh

# Import VERSION
. ./configure.in

##
# This script will enter srcctrl/ and run every script there with:
# 'fetch', 'unpack', 'build', and 'install' successively
#

while getopts c: name
do
  case ${name} in
  c)  CONFIGOPTIONS=$OPTARG
      export CONFIGOPTIONS
      printf 'Global configure options set to %s' ${CONFIGOPTIONS};;
  ?)  printf "Usage: %s: [-i] initrd_version kernel_version" $0
      exit 1;;
  esac
done
shift $(($OPTIND -1))

TOPDIR=${PWD}
export TOPDIR
SRCDIR=${PWD}/src
export SRCDIR
STAGEDIR=${PWD}/stage/initrd-${VERSION}
export STAGEDIR
CDSTAGEDIR=${PWD}/stage/iso-${VERSION}
export CDSTAGEDIR
PATCHDIR=${PWD}/patches
export PATCHDIR
KERNELDIR=${PWD}/kernel/linux-${KERNELVER}
export KERNELDIR
KERNELBIN=${PWD}/kernel/linux-${KERNELVER}/arch/${ARCH}/boot/bzImage
export KERNELBIN

##
# A stupid runparts implementation
#

simple_runparts () {
  _DIR=${1}
  _OPERAND=${2}
  for file in ${_DIR}/*; do
    if [ -x ${file} ]; then
      cd ${TOPDIR}
      sh ${file} ${_OPERAND}
      if [ $? != 0 ]
      then
        return 1
      fi
    fi
  done
}

##
# Begin main
#

if [ ! -d ${STAGEDIR} ]; then
  mkdir -p ${STAGEDIR}
else
  rm -rf ${STAGEDIR}/*
fi

if [ $? != 0 ]; then
  echo 'Failed to create the stage directory.'
fi

cp -av initrd.template/* ${STAGEDIR}

if [ ! -d ${CDSTAGEDIR} ]; then
  mkdir ${CDSTAGEDIR}
else
  rm -rf ${CDSTAGEDIR}/*
fi

if [ $? != 0 ]; then
  echo 'Failed to create the ISO stage directory.'
fi

cp -av iso.template/* ${CDSTAGEDIR}

##
# Fetch, unpack, build and install
#

for operand in fetch unpack build install; do
  simple_runparts srcctrl ${operand}
  if [ $? != 0 ]
  then
    echo "Exiting due to error."
    exit 1
  fi
done

##
# COMPRESS INITRD FOR FOSS EDITION
#

cd ${STAGEDIR}
find . | cpio -o -H newc | gzip > ${TOPDIR}/dist/initrd-v${VERSION}.cpio.gz
if [ $? != 0 ]; then
  echo "Make initramfs failed."
  exit 1
fi

##
# INSTALL TFTP
# maybe the maker doesn't have a tftp directory

cd ${TOPDIR}
if [ -d /tftpboot/bootimage ]; then
  cp -v dist/kernel-${VERSION} /tftpboot/bootimage/kernel-jason
  cp -v dist/initrd-v${VERSION}.cpio.gz /tftpboot/bootimage/bootimage-jason.gz
fi

##
# MAKE ISO FOR FOSS EDITION
#

cd ${TOPDIR}
cp -v dist/kernel-${VERSION} ${CDSTAGEDIR}/isolinux/kernel
cp -v dist/initrd-v${VERSION}.cpio.gz ${CDSTAGEDIR}/isolinux/initrd.img
mkisofs -o dist/cdrom-${VERSION}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table ${CDSTAGEDIR}
if [ $? != 0 ]; then
  echo "Make ISO failed."
  exit 1
fi

##
# OPTIONAL PROPRIETARY OVERLAY
#
cd ${TOPDIR}
if [ -d ../bootimage.private ]; then
  cp -av ../bootimage.private/* ${STAGEDIR}
  perl findso.pl ${STAGEDIR}
  cd ${STAGEDIR}
  find . | cpio -o -H newc | gzip > ${TOPDIR}/dist/initrd-v${VERSION}-nonfree.cpio.gz
  if [ $? != 0 ]; then
    echo "Make nonfree initramfs failed."
    exit 1
  fi
  cd ${TOPDIR}
  cp dist/initrd-v${VERSION}.cpio.gz ${CDSTAGEDIR}/isolinux/initrd.img
  mkisofs -o dist/cdrom-${VERSION}-nonfree.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table ${CDSTAGEDIR}
  if [ $? != 0 ]; then
    echo "Make nonfree ISO failed."
    exit 1
  fi
fi


##
# SUCCESS
#

echo "BUILD COMPLETED SUCESSFULLY"
exit 0

# vim:ts=2:sw=2:expandtab
