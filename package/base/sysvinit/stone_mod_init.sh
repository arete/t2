# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/base/gpm/stone_mod_gpm.sh
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
# [MAIN] 85 init System Init Configuration

write_config() {
	cp /etc/inittab{,.new}
	sed s/.:initdefault/$rl:initdefault/ /etc/inittab.new > /etc/inittab
	rm -f /etc/inittab.new
}

set_rl() {
	gui_menu default_runlevel "Select the default runlevel (Current: $rl)" \
	  '1 ... Single user mode'				'rl=1' \
	  '2 ... Multi user mode without network'		'rl=2' \
	  '3 ... Multi user mode (normal operation)'		'rl=3' \
	  '4 ... Custom use'					'rl=4' \
	  '5 ... Multi user mode with graphical loging manager'	'rl=5'

	write_config
}

main() {
    while
	rl=`grep initdefault /etc/inittab | cut -d : -f2`

	gui_menu gpm 'System Init Configuration.
Select an item to change the value:' \
		"Default runlevel... $rl"   'set_rl' \
		'' '' \
		'Edit the /etc/inittab file'				\
			"gui_edit 'The inittab file' /etc/inittab"
    do : ; done
}

