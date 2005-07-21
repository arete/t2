#!/bin/bash

# Simple custom installer using Xdialog for interaction. After selecting the
# target device it will clone the live-cd onto the hard-disk using
# rsync and even display a progress bar thru Xdialog while doing so.
#
# Copyright (C) 2005 Archivista GmbH
# Copyright (C) 2005 Rene Rebe

shadow=`mktemp`-shadow
parts=

mkdir -p /mnt/target

# collect partitions normally intended for archivista
for x in /dev/hd? /dev/sd? ; do
	[ -e $x ] || continue
	x=${x#/dev/}
	grep -q cdrom /proc/ide/$x/media 2>/dev/null && continue

	parts="$parts /dev/${x}-Reformat_whole_disk"

	for y in /dev/$x[12]; do
		if mount $y /mnt/target 2>/dev/null; then
			if [ -e /mnt/target/home/archivista ]; then
				parts="$parts ${y}-(Archivista)"
			else
				parts="$parts ${y}-(used)"
			fi
			umount /mnt/target
		else
			parts="$parts ${y}-(unknown)"
		fi
	done
done

if [ "$parts" ]; then
	part=`Xdialog --combobox "Please choose the disc partition
to install to:" 8 38 $parts 2>&1`
fi

# empty or reformat?
if [[  $part = *Reformat* ]]; then
	x=${part%-*}
	if Xdialog --yesno "Formating the whole disk $x.
All data will be lost!" 8 38; then
		sfdisk -uM $x << EOT
,4096,L
,4096,L
,1024,S
,,L
EOT
		# install into the first partition on fresh installs ...
		part=/dev/hda1
	else
		exit
	fi
fi

# grep 'root\|archivista' /mnt/target/etc/shadow > $shadow
#                        cat $shadow

part=${part%-*}

if ! Xdialog --yesno "Format partition $part.
All data will be lost!" 8 28; then
	echo cancelled
	exit
fi

echo ok

mkfs.ext3 $part
mount $part /mnt/target

rsync  -arvP /mnt/live/ /mnt/target/ |
  sed -n 's/.* \([0-9]\+.[0-9]\)% .*/\1/p' |
  Xdialog --progress "Installing ..." 8 28

echo installing boot loader ...

mount --bind /dev /mnt/target/dev
mount --bind /proc /mnt/target/proc

chroot /mnt/target stone -text grub <<-EOT
1

2

3

EOT

umount /mnt/target/dev
umount /mnt/target/proc
umount /mnt/target

Xdialog --infobox "Installation finished. You
can safely reboot now." 8 28 200

