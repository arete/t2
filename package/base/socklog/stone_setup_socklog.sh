#!/bin/sh
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../socklog/stone_setup_socklog.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

D_commanddir/socklog-conf unix nobody log D_sysconfdir D_logdir
D_commanddir/socklog-conf klog nobody log D_sysconfdir D_logdir-klog

for y in unix klog; do
	if [ ! -e "D_servicedir/socklog-$y" ]; then
		ln -s D_sysconfdir/$y D_servicedir/socklog-$y
	fi
done
