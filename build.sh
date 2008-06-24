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
# FETCH
#

simple_runparts srcctrl fetch

##
# UNPACK
#

simple_runparts srcctrl unpack

##
# BUILD
#

simple_runparts srcctrl build

##
# INSTALL
#

simple_runparts srcctrl install



# vim:ts=2:sw=2:expandtab
