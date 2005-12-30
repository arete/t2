#!/bin/sh
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../clip/getpatch.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
tempfile=clip-patch.tar.gz.$$
#location=ftp://ftp.linux.ru.net/mirrors/clip
location=ftp://ftp.itk.ru/pub/clip

echo "get: $location/patch.tgz"
if [ -f patch.tgz ]; then
	mv patch.tgz $tempfile
else
#	wget $location/patch.tgz -O $tempfile
	curl $location/patch.tgz > $tempfile
	if [ $? -ne 0 ]; then
		rm -f $tempfile
		exit
	fi
fi

release=$( tar zOxf $tempfile ./clip-prg/clip/release_version 2> /dev/null )
[ -z "$release" ] && release=$( grep -e '^\[V\]' clip.desc | cut -d' ' -f2- | cut -d'-' -f1)
seqno=$( tar zOxf $tempfile ./clip-prg/clip/seq_no.txt 2> /dev/null )

echo "$release-$seqno"

if [ -n "$release" -a -n "$seqno" ]; then
	archdir=../../../download/mirror/c/
	filename=clip-patch-$release-$seqno.tbz2

	if [ -f $archdir/$filename ]; then
		echo "INFO: $filename already grabbed"
	else
		zcat ./$tempfile | bzip2 - > $archdir/$filename
		echo "INFO: $filename catched!"
	fi
	rm -f ./$tempfile
else
	echo "ERROR: take a look into ./$tempfile"
fi
