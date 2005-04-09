#!/bin/bash
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/psion-pda/build_image.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

. $base/misc/target/functions.in

set -e

echo "Preparing root filesystem image from build result ..."

rm -rf $imagelocation{,.squashfs}
mkdir -p $imagelocation ; cd $imagelocation

find $build_root -printf "%P\n" | sed '

# stuff we never need

/^TOOLCHAIN/	d;
/^var\/adm/	d;

/\/include/	d;
/\/src/		d;
/\.a$/		d;
/\.o$/		d;
/\.old$/	d;

/\/games/	d;
/\/local/	d;
/^boot/		d;

# # stuff that would be nice - but is huge and only documentation
/\/man/		d;
/\/doc/		d;

# /etc noise
/^etc\/stone.d/	d;
/^etc\/cron.d/	d;
/^etc\/init.d/	d;

/^etc\/skel/	d;
/^etc\/opt/	d;
/^etc\/conf/	d;
/^etc\/rc.d/	d;

/^opt/		d;

/^\/man\//	d;

/terminfo\/a\/ansi$/	{ p; d; }
/terminfo\/l\/linux$/	{ p; d; }
/terminfo\/x\/xterm$/	{ p; d; }
/terminfo\/n\/nxterm$/	{ p; d; }
/terminfo\/x\/xterm-color$/	{ p; d; }
/terminfo\/x\/xterm-8bit$/	{ p; d; }
/terminfo\/x\/screen$/	{ p; d; }
/terminfo\/v\/vt100$/	{ p; d; }
/terminfo\/v\/vt200$/	{ p; d; }
/terminfo\/v\/vt220$/	{ p; d; }
/terminfo/	d;

' | while read file ; do
	[ "$file" ] || continue
	mkdir -p `dirname $file`
	if [ -d $build_root/$file ] ; then
		mkdir $file
	else
		echo "$file" >> tar.input
	fi
done

copy_with_list_from_file $build_root . $PWD/tar.input
rm tar.input

echo "Preparing root filesystem image from target defined files ..."
ln -s minit sbin/init
copy_from_source $base/target/$target/rootfs .

echo "Creating links for identical files."
link_identical_files

echo "Creating root filesystem image (squashfs) ..."

if [ "$arch_bigendian" = "yes" ]; then
	sqfsopts="-be"
else
	sqfsopts="-le"
fi

mksquashfs $imagelocation{,.squashfs} $sqfsopts > /dev/null

du -sh $imagelocation{,.squashfs}

echo "The image is located at $imagelocation.squasfs."

