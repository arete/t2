# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/livecd/build.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

disksdir="$build_rock/livecd"

pkgloop

rm -rf $disksdir; mkdir -p $disksdir; chmod 700 $disksdir

. scripts/parse-config

. $base/target/$target/build_stage2.sh

. $base/target/$target/build_stage1.sh

if [ -f $base/target/$target/$arch/build.sh ]; then
	. $base/target/$target/$arch/build.sh
fi

echo_header "Creating ISO filesystem description."
cd $disksdir; rm -rf isofs; mkdir -p isofs

echo_status "Creating livecd/isofs directory.."
ln 2nd_stage.img.z isofs/
ln *.img initrd.gz isofs/ 2>/dev/null || true

echo_status "Creating isofs.txt file .."
echo "DISK1	build/${SDECFG_ID}/TOOLCHAIN/livecd/isofs/ `
	`${SDECFG_SHORTID}/" > ../isofs_generic.txt
cat ../isofs_*.txt > ../isofs.txt

echo_status "Done!"

