# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/bootdisk/arch/powerpc/build.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

use_yaboot=1

cd $disksdir

echo_header "Creating cleaning boot directory:"
rm -rfv boot/initrd* boot/System.map* boot/kconfig* boot/zImage*

if [ $use_yaboot -eq 1 ]; then
	echo_header "Creating yaboot setup:"
	#
	echo_status "Extracting yaboot boot loader images."
	mkdir -p boot etc
	tar --use-compress-program=bzip2 \
	    -x -O -f $base/build/${SDECFG_ID}/TOOLCHAIN/pkgs/yaboot.tar.bz2 \
	    usr/lib/yaboot/yaboot > boot/yaboot
	tar --use-compress-program=bzip2 \
	    -x -O -f $base/build/${SDECFG_ID}/TOOLCHAIN/pkgs/yaboot.tar.bz2 \
            usr/lib/yaboot/yaboot.rs6k > boot/yaboot.rs6k
	cp boot/yaboot.rs6k install.bin
	#
	echo_status "Creating yaboot config files."
	cp -v $base/target/$target/arch/powerpc/{boot.msg,ofboot.b} \
	  boot
	#
	# IBM RS/6000
	echo "device=cdrom:" > etc/yaboot.conf
	# Apple New World
	echo "device=cd:" > boot/yaboot.conf
	#
	echo -e "\nmessage=/boot/boot.msg\n" > X
	#
	for x in `egrep 'X .* KERNEL .*' $base/config/$config/packages |
	          cut -d ' ' -f 5-6 | tr ' ' '_'` ; do
		kernel=${x/_*/}
                kernelimg="`grep boot/vmlinux \
		            $build_root/var/adm/flists/$kernel |
		            cut -d ' ' -f 2 | cut -d / -f 1-3 |
	                    uniq | head -n 1`"
                initrd="initrd${kernel/linux/}.gz"
		mv $initrd boot/
                cat >> X << EOT
       
image=/$kernelimg
    label=$kernel
    initrd=/boot/$initrd
    initrd-size=8192
    append="root=/dev/ram devfs=nocompat init=/linuxrc rw"
EOT
        done
	cat X >> etc/yaboot.conf
	cat X >> boot/yaboot.conf
	rm X

	#
	echo_status "Copy more config files."
	cp -v $base/target/$target/arch/powerpc/mapping .
	#
	datadir="build/${SDECFG_ID}/TOOLCHAIN/bootdisk"
	cat > ../isofs_arch.txt <<- EOT
		BOOT	-hfs -part -map $datadir/mapping -hfs-volid "T2SDE_Linux_CD"
		BOOTx	-hfs-bless boot -sysid PPC -l -L -r -T -chrp-boot
		BOOTx   --prep-boot install.bin
		DISK1	$datadir/boot/ boot/
		DISK1	$datadir/etc/ etc/
		DISK1	$datadir/install.bin install.bin
	EOT
#		SCRIPT  sh $base/target/bootdisk/arch/powerpc/bless-rs6k.sh $disksdir
fi

