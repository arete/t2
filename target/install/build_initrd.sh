#!/bin/bash
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/livecd/build_initrd.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

set -e

. $base/misc/target/boot.in

[ "$boot_title" ] || boot_title="T2 SDE Installation"

# Function to create a custom live-cd initrd
extend_initrd()
{
	initrd=$1

	echo "Initrd: $initrd"

	cd $build_toolchain

	# create basic structure
	#
	rm -rf initramfs
	mkdir -p initramfs/{bin,sbin}

	echo "Appending target specific content ..."

	# TODO: add gzip ip
	cp $build_root/usr/embutils/{tar,readlink} initramfs/bin/
	cp $build_root/usr/bin/fget initramfs/bin/

	cp $base/target/install/init initramfs/
	chmod +x initramfs/init

	# create the cpio image
	#
	echo "Appending to initrd archive ..."
	gunzip < $initrd > $initrd.cpio
	( cd initramfs
	  find * | cpio -o -H newc --append --file $initrd.cpio
	)
	gzip -c -9 $initrd.cpio > $initrd
	rm $initrd.cpio

	# display the resulting image
	#
	du -sh $initrd
}

# For each available kernel:
#
arch_boot_cd_pre $isofsdir
for x in `egrep 'X .* KERNEL .*' $base/config/$config/packages |
          cut -d ' ' -f 5` ; do

  kernel=${x/_*/}
  moduledir="`grep lib/modules  $build_root/var/adm/flists/$kernel |
              cut -d ' ' -f 2 | cut -d / -f 1-3 | uniq | head -n 1`"
  kernelver=${moduledir/*\/}
  initrd="initrd-$kernelver.img"
  kernelimg=`ls $build_root/boot/vmlinu?_$kernelver`
  kernelimg=${kernelimg##*/}

  cp $build_root/boot/vmlinu?_$kernelver $isofsdir/boot/
  cp $build_root/boot/$initrd $isofsdir/boot/
  extend_initrd $isofsdir/boot/$initrd

  arch_boot_cd_add $isofsdir $kernelver "$boot_title" \
                   /boot/$kernelimg /boot/$initrd
done

arch_boot_cd_post $isofsdir

