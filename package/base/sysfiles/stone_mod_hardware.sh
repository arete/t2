# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../sysfiles/stone_mod_hardware.sh
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
# [MAIN] 20 hardware Kernel Drivers and Hardware Configuration

set_hw_setup() {
    echo "HARDWARE_SETUP=$1" > /etc/conf/hardware
}

flip_hw_config() {
	local tmp=`mktemp`
	awk "\$0 == \"### $1 ###\", \$0 == \"\" {"'
		if ( /^#[^# ]/ ) {
			sub("^#", "");
			system($0 " >&2");
		} else {
			if ( /^[^# ]/ ) $0 = "#" $0;
			if (/^#modprobe /) {
				cmd = $0;
				sub("^#modprobe", "modprobe -r", cmd);
				system(cmd " >&2");
			}
			if (/^#mount /) {
				cmd = $0;
				sub("^#mount .* ", "umount ", cmd);
				system(cmd " >&2");
			}
		}
	} { print; }' < /etc/conf/kernel > $tmp
	cat $tmp > /etc/conf/kernel; rm -f $tmp

	# this is needed to e.g. initialize /proc/bus/usb/devices
	sleep 1
}

add_hw_config() {
	case $state in
		1) cmd="$cmd '[ ] $name'" ;;
		2) cmd="$cmd '[*] $name'" ;;
		*) cmd="$cmd '[?] $name'" ;;
	esac
	case $state in
		1|2) cmd="$cmd 'flip_hw_config \"$id\"'" ;;
		*)   cmd="$cmd 'true'" ;;
	esac
	id=""
}

store_clock() {
	if [ -f /etc/conf/clock ] ; then
		sed -e "s/clock_tz=.*/clock_tz=$clock_tz/" \
		    -e "s/clock_rtc=.*/clock_rtc=$clock_rtc/" \
		  < /etc/conf/clock > /etc/conf/clock.tmp
		grep -q clock_tz= /etc/conf/clock.tmp || \
		  echo clock_tz=$clock_tz >> /etc/conf/clock.tmp
		grep -q clock_rtc= /etc/conf/clock.tmp || \
		  echo clock_rtc=$clock_rtc >> /etc/conf/clock.tmp
		mv /etc/conf/clock.tmp /etc/conf/clock
	else
		echo -e "clock_tz=$clock_tz\nclock_rtc=$clock_rtc\n" \
		  > /etc/conf/clock
	fi
	if [ -w /proc/sys/dev/rtc/max-user-freq -a "$clock_rtc" ] ; then
		echo $clock_rtc > /proc/sys/dev/rtc/max-user-freq
	fi
}

set_zone() {
	clock_tz=$1
	hwclock --hctosys --$clock_tz
	store_clock
}

set_rtc() {
	gui_input "Set new enhanced real time clock precision" \
                  "$clock_rtc" "clock_rtc"
	store_clock
}

main() {
    while
        HARDWARE_SETUP=rockplug
	if [ -f /etc/conf/hardware ]; then
	    . /etc/conf/hardware
	fi
	for x in hwscan rockplug; do
	    if [ "$HARDWARE_SETUP" = $x ]; then
		eval "hw_$x='<*>'"
	    else
		eval "hw_$x='< >'"
	    fi
	done

	clock_tz=utc
	clock_rtc="`cat /proc/sys/dev/rtc/max-user-freq 2> /dev/null`"
	if [ -f /etc/conf/clock ]; then
	    . /etc/conf/clock
	fi

	cmd="gui_menu hw 'Kernel Drivers and Hardware Configuration'"
	if [ "$HARDWARE_SETUP" = rockplug ]; then
	    cmd="$cmd \"$hw_rockplug Use ROCKPLUG to configure hardware.\""
	    cmd="$cmd \"set_hw_setup rockplug\"";
	    cmd="$cmd \"$hw_hwscan Use hwscan to configure hardware.\""
	    cmd="$cmd \"set_hw_setup hwscan\"";
	    cmd="$cmd \"\" \"\"";
	    cmd="$cmd 'Edit/View PCI configuration'";
	    cmd="$cmd \"gui_edit PCI /etc/conf/pci\""
	    cmd="$cmd 'Edit/View USB configuration'";
	    cmd="$cmd \"gui_edit USB /etc/conf/usb\""
	    cmd="$cmd \"\" \"\"";
	    
	    #@FIXME single shot menu?

	    cmd="$cmd 'Re-create initrd image (mkinitrd, `uname -r`)'"
	    cmd="$cmd 'gui_cmd mkinitrd mkinitrd' '' ''"
	fi
	    
	if [ "$HARDWARE_SETUP" = hwscan ]; then
	    cmd="$cmd \"$hw_rockplug Use ROCKPLUG to configure hardware.\" \"set_hw_setup rockplug\"";
	    cmd="$cmd \"$hw_hwscan Use hwscan to configure hardware.\" \"set_hw_setup hwscan\"";
	    cmd="$cmd \"\" \"\"";
	    cmd="$cmd 'Edit /etc/conf/kernel (kernel drivers config file)'"
	    cmd="$cmd \"gui_edit 'Kernel Drivers Config File' /etc/conf/kernel\""
	    cmd="$cmd 'Re-create initrd image (mkinitrd, `uname -r`)'"
	    cmd="$cmd 'gui_cmd mkinitrd mkinitrd' '' ''"
	    hwscan -d -s /etc/conf/kernel

	    id=""
	    while read line; do
		if [ "${line#\#\#\# }" != "${line}" -a \
		    "${line% \#\#\#}" != "${line}" ]
		    then
		    id="${line#\#\#\# }"; id="${id% \#\#\#}"
		    state=0; name="Unamed Kernel Driver"
		elif [ -z "$id" ]; then
		    continue
		elif [ "${line#\# }" != "${line}" ]; then
		    name="${line#\# }"
		elif [ "${line#\#[!\# ]}" != "${line}" ]; then
		    [ $state -eq 0 ] && state=1
		    [ $state -eq 2 ] && state=3
		elif [ "${line#[!\# ]}" != "${line}" ]; then
		    [ $state -eq 0 ] && state=2
		    [ $state -eq 1 ] && state=3
		elif [ -z "$line" ]; then
		    add_hw_config
		fi
	    done < /etc/conf/kernel
	    [ -z "$id" ] || add_hw_config
	    cmd="$cmd '' ''"
	fi	   

	if [ "$clock_tz" = localtime ] ; then
	    cmd="$cmd '[*] Use localtime instead of utc' 'set_zone utc'"
	else
	    cmd="$cmd '[ ] Use localtime instead of utc' 'set_zone localtime'"
	    clock_tz=utc
	fi
	cmd="$cmd 'Set enhanced real time clock precision ($clock_rtc)' set_rtc"
 
	eval "$cmd"
    do : ; done

    return
}

