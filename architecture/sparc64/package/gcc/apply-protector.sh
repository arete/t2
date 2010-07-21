# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../gcc/apply-protector.sh
# Copyright (C) 2004 - 2006 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

# only try to apply protector if available
pfile=`match_source_file -p protector` || true
if [ "$pfile" ] ; then
	echo "Inserting SPP ..."
	ppatch=`tar -v $taropt $pfile | grep 'dif\$' | head -n 1`

	if [ "$ppatch" -a -f $ppatch ]; then
		[ -f $confdir/protector-adapter.diff ] &&
			patch -p0 $ppatch $confdir/protector-adapter.diff
		patch -p0  < $ppatch
	else
		abort "Protector patch not found"
	fi
	if [ -f protector.c ] ; then
		mv protector.{c,h} gcc/
	fi
else
	echo "No stack-protector available for $pkg ..."
fi

