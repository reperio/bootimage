#!/bin/ash

PRODUCT_NAME="Advanced Clustering's Cloner"
PRODUCT_VERSION="2.1"

CLONER_IMAGE_PATH="cloner-2/images"
CLONER_HOST_PATH="cloner-2/hosts"

. /tmp/cmdline.dat

replace_setting() {

	KEY=${1}
	VALUE=${2}

	sed 's/${KEY}=.*//' /tmp/cmdline.dat > /tmp/cmdline.new
	echo "${KEY}=\"${VALUE}\"" >> /tmp/cmdline.new

	mv /tmp/cmdline.new /tmp/cmdline.dat
	. /tmp/cmdline.dat
}
