# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../lilo/stone_mod_lilo.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
#
# [MAIN] 70 lilo LILO Boot Loader Setup

create_kernel_list() {
        first=1
        for x in `(cd /boot/ ; ls vmlinuz_* ) | sort -r` ; do
                if [ $first = 1 ] ; then
                        label=linux ; first=0
                else
                        label=linux-${x/vmlinuz_/}
                fi

                cat << EOT

image=/boot/$x
        label=$label
        append="root=$rootdev"
        read-only

EOT
        done
}

create_lilo_conf() {
	i=0 ; rootdev="`grep ' / ' /proc/mounts | tail -n 1 | \
					awk '/\/dev\// { print $1; }'`"
	rootdev="$( cd `dirname $rootdev` ; pwd -P )/$( basename $rootdev )"
	while [ -L $rootdev ] ; do
		directory="$( cd `dirname $rootdev` ; pwd -P )"
		rootdev="$( ls -l $rootdev | sed 's,.* -> ,,' )"
		[ "${rootdev##/*}" ] && rootdev="$directory/$rootdev"
		i=$(( $i + 1 )) ; [ $i -gt 20 ] && rootdev="Not found!"
	done
	bootdev="$( dirname $rootdev )/disc"

	cat << EOT > /etc/lilo.conf
boot=$bootdev
delay=40
timeout=60
prompt
lba32
EOT

	create_kernel_list >> /etc/lilo.conf

	cat << EOT >> /etc/lilo.conf
image=/boot/memtest86.bin
	label=memtest
	optional
EOT
	gui_message "This is the new /etc/lilo.conf file:

$( cat /etc/lilo.conf )"

}

main() {
    while
        gui_menu lilo 'LILO Boot Loader Setup' \
                '(Re-)Create default /etc/lilo.conf' 'create_lilo_conf' \
                '(Re-)Install LILO in MBR of /dev/discs/disc0/disc' \
			'gui_cmd "Installing LILO in MBR" "lilo -v"' \
                "Edit /etc/lilo.conf (recommended before installing LILO)" \
                        "gui_edit 'LILO Config File' /etc/lilo.conf"
    do : ; done
}

