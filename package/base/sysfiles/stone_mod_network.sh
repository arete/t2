# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/base/iproute2/stone_mod_network.sh
# ROCK Linux is Copyright (C) 1998 - 2003 Clifford Wolf
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. A copy of the GNU General Public
# License can be found at Documentation/COPYING.
# 
# Many people helped and are helping developing ROCK Linux. Please
# have a look at http://www.rocklinux.org/ and the Documentation/TEAM
# file for details.
# 
# --- ROCK-COPYRIGHT-NOTE-END ---
#
# [MAIN] 20 network Network Configuration

### DYNAMIC NEW-STYLE CONFIG ###

rocknet_base="/etc/network"

edit() {
	gui_edit "Edit file $1" "$1"
	exec $STONE network
}

read_section() {
	local globals=1
	local readit=0
	local i=0

	unset tags
	unset interfaces


	[ "$1" = "" ] && readit=1
	while read netcmd para
	do
		if [ -n "$netcmd" ]; then
			netcmd="${netcmd//-/_}"
			para="$( echo "$para" | sed 's,[\*\?],\\&,g' )"
			if [ "$netcmd" = "interface" ] ; then
				prof="$( echo "$para" | sed 's,[(),],_,g' )"
				[ "$prof" = "$1" ] && readit=1 || readit=0
				globals=0
				interfaces="$interfaces $prof"
			fi
			if [ $readit = 1 ] ; then
				tags[$i]="$netcmd $para"
				i=$((i+1))
			fi
		fi
	done < <( sed 's,#.*,,' < "$rocknet_base"/config )
}

write_section() {
	local globals=1
	local passit=1
	local dumped=0

	[ "$1" = "" ] && passit=0

	echo -n > $rocknet_base/config.new

	while read netcmd para
	do
		if [ -n "$netcmd" ]; then
			netcmd="${netcmd//-/_}"
			para="$( echo "$para" | sed 's,[\*\?],\\&,g' )"
			if [ "$netcmd" = "interface" ] ; then
				prof="$( echo "$para" | sed 's,[(),],_,g' )"
				[ "$prof" = "$1" ] && passit=0 || passit=1
				globals=0

				# write out a separating newline
				echo "" >> $rocknet_base/config.new
			fi

			# when we reached the matching section dump the
			# mew tags ...
			if [ $passit = 0 -a $dumped = 0 ] ; then
			  for (( i=0 ; $i < ${#tags[@]} ; i=i+1 )) ; do
				netcmd="${tags[$i]}"
				[ $globals = 0 ] && [[ "$netcmd" != interface* ]] && \
				  echo -en "\t" >> \
				  $rocknet_base/config.new
				echo "${tags[$i]}" >> \
				  $rocknet_base/config.new
			  done
			  dumped=1
			fi

			if [ $passit = 1 ] ; then
				[ $globals = 0 -a \
				  "$netcmd" != "interface" ] && \
				  echo -en "\t" >> \
				  $rocknet_base/config.new
				echo "$netcmd $para" >> \
					$rocknet_base/config.new
			fi
		fi
	done < <( cat < "$rocknet_base"/config )
	mv $rocknet_base/config{.new,}
}

edit_tag() {
	tag="${tags[$1]}"
	name="$tag"
	gui_input "Set new value for tag '$name'" \
	          "$tag" "tag"
	tags[$1]="$tag"
}

edit_global_tag() {
	edit_tag $@
	write_section ""
}

add_tag() {
	tta="$@"
	if [ "$tta" = "" ] ; then
		cmd="gui_menu add_tag 'Add tag of type'"

		while read tag module ; do
			cmd="$cmd '`printf "%-12s %s" "$tag" "($module)"`' 'tta=$tag'"
		done < <( cd /etc/network/modules/ ; grep public_ * | sed -e \
		          's/\([a-zA-Z0-9_-]*\).sh:public_\([a-zA-Z0-9_-]*\).*/\2 \1/' \
		          | sort +2 +1)
		eval "$cmd"
	fi

	if [ "$tta" ] ; then
		tagno=${#tags[@]}
		tags[$tagno]="$tta"
		edit_tag $tagno
	fi
}

add_global_tag() {
	add_tag $@
	write_section ""
}

edit_if() {
	read_section "$1"

	quit=0
	while 
		cmd="gui_menu if_edit 'Configure interface ${1//_/ }'"
		for (( i=0 ; $i < ${#tags[@]} ; i=i+1 )) ; do
			cmd="$cmd '${tags[$i]}' 'edit_tag $i'"
		done

		cmd="$cmd '' '' 'Add new tag' 'add_tag'"
		cmd="$cmd 'Delete this interface/profile' 'del_interface $1 && quit=1'"

		# tiny hack since gui_menu return 0 or 1 depending on the exec
		# status of e.g. dialog - and thus a del_interface && false cannot
		# be used ...

		eval "$cmd" || quit=1
		[ $quit = 0 ]
	do : ; done
	write_section "$1"
}

add_interface() {
	if="$1"

	gui_input "The new interface name (and profile)" \
	          "$if" "if"
	unset tags
	tags[0]="interface $if"

	# for now we need to add the interface line into the file
	# so the parse finds the right place to add the new tags
	echo -e "\ninterface $if\n#added by stone" >> "$rocknet_base"/config

	if gui_yesno "Use DHCP to obtain the configuration?" ; then
		add_tag "dhcp"
	else
		add_tag "ip 192.168.5.1/24"
		add_tag "gw 192.168.5.1"
		add_tag "nameserver 192.168.5.1"
	fi

	write_section "$if"
} 

del_interface() {
	unset tags
	write_section "$1"
}

### STATIC OLD-STYLE CONFIG ###

set_name() {
	old1="$HOSTNAME" old2="$HOSTNAME.$DOMAINNAME" old3="$DOMAINNAME"
	if [ $1 = HOSTNAME ] ; then
		gui_input "Set a new hostname (without domain part)" \
		          "${!1}" "$1"
	else
		gui_input "Set a new domainname (without host part)" \
		          "${!1}" "$1"
	fi
	new="$HOSTNAME.$DOMAINNAME $HOSTNAME"

	echo "$HOSTNAME" > /etc/HOSTNAME ; hostname "$HOSTNAME"

	#ip="`echo $IPADDR | sed 's,[/ ].*,,'`"
	#if grep -q "^$ip\\b" /etc/hosts ; then
	#	tmp="`mktemp`"
	#	sed -e "/^$ip\\b/ s,\\b$old2\\b[ 	]*,,g" \
	#	    -e "/^$ip\\b/ s,\\b$old1\\b[ 	]*,,g" \
	#	    -e "/^$ip\\b/ s,[ 	]\\+,&$new ," < /etc/hosts > $tmp
	#	cat $tmp > /etc/hosts ; rm -f $tmp
	#else
	#	echo -e "$ip\\t$new" >> /etc/hosts
	#fi

	if [ $1 = DOMAINNAME ] ; then
		tmp="`mktemp`"
		grep -vx "search $old3" /etc/resolv.conf > $tmp
		[ -n "$DOMAINNAME" ] && echo "search $DOMAINNAME" >> $tmp
		cat $tmp > /etc/resolv.conf
		rm -f $tmp
	fi
}

set_dns() {
	gui_input "Set a new (space seperated) list of DNS Servers" "$DNSSRV" "DNSSRV"
	DNSSRV="`echo $DNSSRV`" ; [ -z "$DNSSRV" ] && DNSSRV="none"

	tmp="`mktemp`" ; grep -v '^nameserver\b' /etc/resolv.conf > $tmp
	for x in $DNSSRV ; do
		[ "$x" != "none" ] && echo "nameserver $x" >> $tmp
	done
	cat $tmp > /etc/resolv.conf
	rm -f $tmp
}

HOSTNAME="`hostname`"
DOMAINNAME="`hostname -d 2> /dev/null`"

tmp="`mktemp`"
grep '^nameserver ' /etc/resolv.conf | tr '\t' ' ' | tr -s ' ' | \
    sed 's,^nameserver *\([^ ]*\),DNSSRV="$DNSSRV \1",' > $tmp
DNSSRV='' ; . $tmp ; DNSSRV="`echo $DNSSRV`"
[ -z "$DNSSRV" ] && DNSSRV="none" ; rm -f $tmp

main() {
    first_run=1
    while

	# read global section and interface list ...
	read_section ""

	p_interfaces=$(ip link | egrep '[^:]*: .*' | \
	               sed 's/[^:]*: \([a-z0-9]*\): .*/\1/' | \
	               grep -v -e lo -e sit)

	if [ $first_run = 1 ] ; then
		first_run=0
		# check if a section for the interface is already present
		for x in $p_interfaces ; do
			if [[ $interfaces != *$x* ]] ; then
			  if gui_yesno "Unconfigured interface $x detected. \
Do you want to create an interface section?" ; then
				add_interface "$x"
			  fi
			fi
		done
		read_section ""
	fi

	cmd="gui_menu network 'Network Configuration - Select an item to
change the value

WARNING: This script tries to adapt /etc/network/config and /etc/hosts
according to your changes. Changes only take affect the next time
rocknet is executed.'"

	cmd="$cmd 'Static hostname:   $HOSTNAME'   'set_name HOSTNAME'"
	cmd="$cmd 'Static domainname: $DOMAINNAME' 'set_name DOMAINNAME'"
	cmd="$cmd 'Static DNS-Server: $DNSSRV'     'set_dns' '' ''"

	for (( i=0 ; $i < ${#tags[@]} ; i=i+1 )) ; do
		cmd="$cmd '${tags[$i]}' 'edit_global_tag $i'"
	done
	cmd="$cmd 'Add new global tag' 'add_global_tag' '' ''"

	for if in $interfaces ; do
		cmd="$cmd 'Edit interface ${if//_/ }' 'edit_if $if'"
	done

	cmd="$cmd 'Add new interface/profile' 'add_interface' '' ''"

	cmd="$cmd 'Configure runlevels for network service'"
	cmd="$cmd '$STONE runlevel edit_srv network'"
	cmd="$cmd '(Re-)Start network init script'"
	cmd="$cmd '$STONE runlevel restart network'"
	cmd="$cmd '' ''"

	cmd="$cmd 'View/Edit /etc/resolv.conf file'     'edit /etc/resolv.conf'"
	cmd="$cmd 'View/Edit /etc/hosts file'           'edit /etc/hosts'"
	cmd="$cmd 'View/Edit $rocknet_base/config file' 'edit $rocknet_base/config'"

	eval "$cmd"
    do : ; done
}

