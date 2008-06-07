#!/bin/sh

# Import VERSION
. ./configure.in

##
# This script will enter srcctrl/ and run every script there with:
# 'fetch', 'unpack', and 'build' successively
#
# If a module needs to do the install to STAGEDIR itself, that should be done
# inside of make_new_initrd in the TOPDIR
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
# FETCH
#

for file in srcctrl/*; do
  if [ -x ${file} ]; then
    cd ${TOPDIR}
    sh ${file} fetch
  fi
done

##
# UNPACK
#

for file in srcctrl/*; do
  if [ -x ${file} ]; then
    cd ${TOPDIR}
    sh ${file} unpack
  fi
done

##
# BUILD
#

for file in srcctrl/*; do
  if [ -x ${file} ]; then
    cd ${TOPDIR}
    sh ${file} build
  fi
done


