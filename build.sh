#!/bin/bash

# Import VERSION
. ./configure.in


##
# This script will enter srcctrl/ and run every script there with:
# 'fetch', 'unpack', 'build', and 'install' successively
#

while getopts pagc: name
do
  case ${name} in
  a)  DISABLEAMD='yes'
      export DISABLEAMD
      echo 'Disabled AMD building. xhpl.amd will not be built.';;
  g)  USEGOTO='yes'
      export USEGOTO
      echo 'Using GOTO in place of MKL and ACML. For acedemic and experimental use only.';;
  c)  CONFIGOPTIONS=$OPTARG
      export CONFIGOPTIONS
      printf 'Global ./configure options set to %s\n' ${CONFIGOPTIONS};;
  p)  NO_ANSI=1
      export NO_ANSI ;;
  ?)  printf "Usage: %s: [-a] [-g] [-c configure_opts]\n" $0
      exit 1;;
  esac
done
shift $(($OPTIND -1))

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
# A stupid runparts implementation
#

simple_runparts () {
  _DIR=${1}
  _OPERAND=${2}

  for file in ${_DIR}/*; do
    if [ -x ${file} ]; then

      _LOGFILE="${LOGDIR}/`basename ${file}`-${VERSION}.log"

      echo -en "Running ${_OPERAND} on ${ANSI_BLUE}`basename ${file}`${ANSI_DONE}"

      if [ "${_OPERAND}" = "fetch" ]
      then
        sh ${file} ${_OPERAND} > ${_LOGFILE}
      else
        sh ${file} ${_OPERAND} >> ${_LOGFILE}
      fi
      if [ $? != 0 ]
      then
        echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
        echo ""
        tail -20 ${_LOGFILE}
        echo -e "Log file from stdout available here ${_LOGFILE}"
        return 1
      fi
      echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"
    else
      echo -e "${ANSI_RED}Skipping `basename ${file}` execute bit not set ${ANSI_DONE}"
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
  echo 'Failed to create and clean the stage directory.'
  exit 1
fi

##
# Cleanup the latest directory
#

if [ -d "${TOPDIR}/dist/latest" ]
then
	rm -f ${TOPDIR}/dist/latest/*
fi



cd ${STAGEDIR}
SKEL='usr usr/bin usr/local usr/local/bin usr/lib usr/share usr/src tmp lib lib/terminfo var var/lib var/log etc lib64 usr/lib64 run'
for dir in $SKEL; do
  mkdir ${dir}
  if [ $? != 0 ]; then
    echo "Failed to create a required directory in the target stage.\n"
    exit 1
  fi
done


# drop a version file in stage directory
echo "VERSION=${VERSION}" > ${STAGEDIR}/etc/breakin-release
echo "BUILD_NUMBER=${BUILD_NUMBER}" >> ${STAGEDIR}/etc/breakin-release
echo "BUILD_HOST=`hostname`" >> ${STAGEDIR}/etc/breakin-release
echo "GIT_COMMIT=`git log -n 1 --pretty=format:"%H"`" >> ${STAGEDIR}/etc/breakin-release

chmod +t tmp
if [ $? != 0 ]; then
  echo "Failed to sticky bit on tmp.\n"
  exit 1
fi

if [ ! -d ${CDSTAGEDIR} ]; then
  mkdir ${CDSTAGEDIR}
else
  rm -rf ${CDSTAGEDIR}/*
fi
if [ $? != 0 ]; then
  echo 'Failed to create the ISO stage directory.'
  exit 1
fi

cp -av ${TOPDIR}/iso.template/* ${CDSTAGEDIR} > ${LOGDIR}/iso-cp.log.${VERSION}
if [ $? != 0 ]; then
  echo 'Failed to create the ISO stage directory.'
  exit 1
fi

if [ ! -d ${TARSTAGEDIR} ]; then
  mkdir ${TARSTAGEDIR}
else
  rm -rf ${TARSTAGEDIR}/*
fi
if [ $? != 0 ]; then
  echo 'Failed to create the TAR stage directory.'
  exit 1
fi

cp -av ${TOPDIR}/dist/examples ${TOPDIR}/dist/README ${TARSTAGEDIR} > ${LOGDIR}/tar-cp.log.${VERSION}
if [ $? != 0 ]; then
  echo 'Failed to create the TAR stage directory.'
  exit 1
fi


##
# Fetch, unpack, build and install
#

cd ${TOPDIR}
#for operand in install; do
for operand in fetch unpack build install; do
  simple_runparts ${TOPDIR}/srcctrl ${operand}
  if [ $? != 0 ]
  then
    echo "Exiting due to error."
    exit 1
  fi
done

##
# GATHER THE SHARED OBJECTS
#

echo -en "Finding shared libraries for all binaries"
perl ${TOPDIR}/findso.pl ${STAGEDIR}

# all locally install support libs
LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
export LD_LIBRARY_PATH
perl ${TOPDIR}/findso.pl ${STAGEDIR}

echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

# add a few additional manually

ADDLLIBS="\
/usr/lib/libncurses.so.5 \
/lib/librt.so.1 \
/lib/ld-linux.so.2 \
/lib/libc.so.6 \
/lib/libdl.so.2 \
/lib/libgcc_s.so.1 \
/lib/libm.so.6 \
/lib/libncurses.so.5 \
/lib/libpthread.so.0 \
/lib/libstdc++.so.6 \
/lib/libtinfo.so.5 \
/usr/lib64/libstdc++.so.6 \
/usr/lib64/libgomp.so.1 \
^/lib64/libgcc_s.so.1 \
ld-linux-x86-64.so.2 \
libnss_compat.so.2 \
libnss_dns.so.2 \
libnss_files.so.2 \
libresolv.so.2 \
librt.so.1 \
libuuid.so.1 \
libnuma.so \
libparted-2.1.so.0"

echo -en "Adding extra shared libraries"
for file in $ADDLLIBS; do
  uri=$(/sbin/ldconfig -p | awk -F'> ' '{print $2}' | grep -m1 ${file})
  if [ $uri ]; then
    cp -p --parents ${uri} ${STAGEDIR}
  fi
done
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

# remove locale data

echo -en "Removing locale data to save space"
rm -rf ${STAGEDIR}/usr/share/locale/*
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

# create the ld library cache

echo -en "Creating ld.so.conf and ld.so.cache in initramfs"
#echo "/act/gcc-4.9.2/lib64" >> ${STAGEDIR}/etc/ld.so.conf
echo "/act/gcc-4.7.2/lib64" >> ${STAGEDIR}/etc/ld.so.conf
/sbin/ldconfig -r ${STAGEDIR} -f /etc/ld.so.conf -C /etc/ld.so.cache
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

# Create the cpio image under root so that special files can be made
fakeroot ${TOPDIR}/build-img.sh
if [ $? != 0 ]; then
  exit 1
fi

##
# INSTALL TFTP
# maybe the maker doesn't have a tftp directory

cd ${TOPDIR}
if [ -d /tftpboot/bootimage ]; then
  cp -v dist/kernel-${VERSION} /tftpboot/bootimage/kernel-jason
  cp -v dist/initrd-${VERSION}.cpio.lzma /tftpboot/bootimage/bootimage-jason.lzma
fi

##
# MAKE TARBALL FOR FOSS EDITION
#

echo -en "Creating tarball dist/bootimage-${VERSION}.tbz2"
cp -v ${TOPDIR}/dist/kernel-${VERSION} ${TARSTAGEDIR} > ${LOGDIR}/tar-cp.log.${VERSION}
cp -v ${TOPDIR}/dist/initrd-${VERSION}.cpio.lzma ${TARSTAGEDIR} > ${LOGDIR}/tar-cp.log.${VERSION}
cd ${TOPDIR}/stage
tar -cvjf bootimage-${VERSION}.tbz2 bootimage-${VERSION}
mv -v bootimage-${VERSION}.tbz2 ${TOPDIR}/dist/
if [ $? != 0 ]; then
  echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
  exit 1
fi
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

##
# MAKE RPM FOR FOSS EDITION
#

RELEASE=1
if [ "${BUILD_NUMBER}" != "" ]
then
	RELEASE="${BUILD_NUMBER}"
fi

echo -en "Creating RPM dist/bootimage-${VERSION}.rpm"
cd ${TOPDIR}/dist
rpmbuild -bb --define "_topdir ${TOPDIR}/rpmbuild" --define "_rpmdir ${TOPDIR}/dist" --define "version ${VERSION}" --define "release ${BUILD_NUMBER}" bootimage.spec
if [ $? != 0 ]; then
  echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
  exit 1
fi
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

##
# MAKE ISO FOR FOSS EDITION
#

echo -en "Creating ISO dist/bootimage-${VERSION}.iso"
cd ${TOPDIR}
cp -v dist/kernel-${VERSION} ${CDSTAGEDIR}/isolinux/kernel > /dev/null
cp -v dist/initrd-${VERSION}.cpio.lzma ${CDSTAGEDIR}/isolinux/initrd.img > /dev/null
genisoimage -o dist/bootimage-${VERSION}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table ${CDSTAGEDIR}
if [ $? != 0 ]; then
  echo -e "${ANSI_LEFT}${ANSI_RED}[ FAIL ]${ANSI_DONE}"
  exit 1
fi
echo -e "${ANSI_LEFT}${ANSI_GREEN}[ OK ]${ANSI_DONE}"

##
# OPTIONAL PROPRIETARY OVERLAY
#
cd ${TOPDIR}
if [ -d ../bootimage.private ]; then
  cp -av ../bootimage.private/* ${STAGEDIR}
  fakeroot perl findso.pl ${STAGEDIR}
  cd ${STAGEDIR}
  find . | cpio -o -H newc | gzip > ${TOPDIR}/dist/initrd-${VERSION}-nonfree.cpio.gz
  if [ $? != 0 ]; then
    echo "Make nonfree initramfs failed."
    exit 1
  fi
  cd ${TOPDIR}
  cp dist/initrd-${VERSION}-nonfree.cpio.gz ${CDSTAGEDIR}/isolinux/initrd.img
  mkisofs -o dist/bootimage-${VERSION}-nonfree.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table ${CDSTAGEDIR}
  if [ $? != 0 ]; then
    echo "Make nonfree ISO failed."
    exit 1
  fi
fi

##
#  Copy the goods into the latest directory
#
cp dist/initrd-${VERSION}.cpio.lzma ${TOPDIR}/dist/latest/initrd-${VERSION}-${RELEASE}.cpio.lzma
cp dist/kernel-${VERSION} ${TOPDIR}/dist/latest/kernel-${VERSION}-${RELEASE}
cp dist/bootimage-${VERSION}.tbz2 ${TOPDIR}/dist/latest/bootimage-${VERSION}-${RELEASE}.tbz2
cp dist/bootimage-${VERSION}.iso ${TOPDIR}/dist/latest/bootimage-${VERSION}-${RELEASE}.iso
cp dist/${ARCH}/bootimage-${VERSION}-${RELEASE}*.rpm ${TOPDIR}/dist/latest


##
# SUCCESS
#

echo -e "${ANSI_GREEN}BUILD COMPLETED SUCESSFULLY${ANSI_DONE}"
exit 0

# vim:ts=2:sw=2:expandtab
