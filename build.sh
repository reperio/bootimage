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
  DIR=${1}
  OPERAND=${2}
  for file in ${1}/*; do
    if [ -x ${file} ]; then
      cd ${TOPDIR}
      sh ${file} ${OPERAND}
    fi
  done
}

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
