
set -e
taropt="--use-compress-program=bzip2 -xf"

echo_header "Creating 2nd stage filesystem:"
mkdir -p $disksdir/2nd_stage
cd $disksdir/2nd_stage
mkdir -p mnt/source mnt/target
#
package_map='       +00-dirtree
+glibc	            -gcc                -linux-header
+linux24            +linux26            +linux24benh
-binutils           -bin86              -nasm               -dietlibc
+lilo               +yaboot             +aboot              +grub
+silo               +parted             +mac-fdisk          +pdisk
+xfsprogs           +mkdosfs            +jfsutils
+e2fsprogs          +reiserfsprogs      +reiser4progs       +genromfs
+popt               +raidtools          +mdadm
+lvm                +lvm2               +device-mapper
+dump               +eject              +disktype           -patchutils
+hdparm             +memtest86          +cpuburn            +bonnie++
-mine               -bize               -termcap            +ncurses
+readline           -strace             -perl
-m4                 -time               -gettext            -zlib
+bash               +attr               +acl                +findutils
+mktemp             +coreutils          -diffutils          -patch
-make               +grep               +sed                +gzip
+tar                +gawk               -flex               +bzip2
-texinfo            +less               -groff              -man
+nvi                -bison              +bc                 +cpio
+ed                 -autoconf           -automake           -libtool
+curl               +wget               +dialog             +minicom
+lrzsz              +rsync              +tcpdump            +module-init-tools
+sysvinit           +shadow             +util-linux         +wireless-tools
+net-tools          +procps             +psmisc             +rockplug
+modutils           +pciutils           -cron               +portmap
+sysklogd           +devfsd             +setserial          +iproute2
+netkit-base        +netkit-ftp         +netkit-telnet      +netkit-tftp
+sysfiles           +libpcap            +iptables           +tcp_wrappers
-kiss               +kbd		-syslinux           +ntfsprogs
-ethtool            -uml_utilities      -bdb
+libol'

if [ -f ../../pkgs/bize.tar.bz2 -a ! -f ../../pkgs/mine.tar.bz2 ] ; then
	packager=bize
else
	packager=mine
fi

package_map="$( echo "+$packager $package_map" | tr "\t" " " | tr -s ' ' | tr ' ' '\n')"
forgotten_packages=

echo_status "Extracting the packages archives."
for x in $( ls ../../pkgs/*.tar.bz2 | tr . / | cut -f8 -d/ )
do
	y=$( echo "$package_map" | sed -n -e "s,^\([-+]\)$x$,\1,p" )

	if [ -z "$y" ]; then
		echo_error "\`- Not found in \$package_map: $x"
		echo_error "    ... fix target/$target/build_stage2.sh"
		var_append forgotten_packages ' ' $x
	elif [ "$y" != "-" ]; then
		echo_status "\`- Extracting $x.tar.bz2 ..."
		tar -p $taropt ../../pkgs/$x.tar.bz2
	fi
done

if [ "$forgotten_packages" ]; then
	echo_status "Forgotten packages summary:"
	for x in $forgotten_packages; do
		echo_error "\`- $x"
	done
fi
#
echo_status "Saving boot/ lib/modules/ - for the 2nd stage ..."
rm -rf ../boot ; mkdir ../boot
mv boot/* ../boot/
rm -rf ../lib ; mkdir ../lib
mv lib/modules ../lib/

echo_status "Remove the stuff we do not need ..."
rm -rf home usr/{local,doc,man,info,games,share}
rm -rf var/adm/* var/games var/adm var/mail var/opt
rm -rf usr/{include,src} usr/*-linux-gnu {,usr/}lib/*.{a,la,o}
for x in usr/lib/*/; do rm -rf ${x%/}; done
#
echo_status "Installing some terminfo databases ..."
tar $taropt ../../pkgs/ncurses.tar.bz2 \
	usr/share/terminfo/a/ansi usr/share/terminfo/l/linux \
	usr/share/terminfo/n/nxterm usr/share/terminfo/x/{xterm,xterm-new} \
	usr/share/terminfo/v/vt{100,200,220} \
	usr/share/terminfo/s/screen
#
if [ -f ../../pkgs/kbd.tar.bz2 ] ; then
	echo_status "Installing some Kymaps ..."
	tar $taropt ../../pkgs/kbd.tar.bz2 \
		usr/share/kbd/keymaps/i386/{include,qwerty,qwertz} \
		usr/share/kbd/keymaps/include
	find usr/share/kbd -name '*dvo*' -o -name '*az*' -o -name '*fgG*' | \
		xargs rm -f
fi
#
if [ -f ../../pkgs/pciutils.tar.bz2 ] ; then
	echo_status "Installing pci.ids ..."
	tar $taropt ../../pkgs/pciutils.tar.bz2 \
		usr/share/pci.ids
fi
#
echo_status "Creating 2nd stage linuxrc."
cp $base/target/$target/linuxrc2.sh linuxrc ; chmod +x linuxrc
cp $base/target/$target/shutdown sbin/shutdown ; chmod +x sbin/shutdown
echo '$STONE install' > etc/stone.d/default.sh
#
echo_status "Creating 2nd_stage.tar.gz archive."
tar -czf ../2nd_stage.tar.gz * ; cd ..


echo_header "Creating small 2nd stage filesystem:"
mkdir -p 2nd_stage_small ; cd 2nd_stage_small
mkdir -p dev proc tmp bin lib etc share
mkdir -p mnt/source mnt/target
ln -s bin sbin ; ln -s . usr

#

progs="agetty bash cat cp date dd df ifconfig ln ls $packager mkdir mke2fs \
       mkswap mount mv rm reboot route sleep swapoff swapon sync umount \
       eject chmod chroot grep halt rmdir sh shutdown uname killall5 \
       stone mktemp sort fold sed mkreiserfs cut head tail disktype"

progs="$progs fdisk sfdisk"

if [ $arch = ppc ] ; then
	progs="$progs mac-fdisk pdisk"
fi

if [ $packager = bize ] ; then
	progs="$progs bzip2 md5sum"
fi

echo_status "Copy the most important programs ..."
for x in $progs ; do
	fn=""
	[ -f ../2nd_stage/bin/$x ] && fn="bin/$x"
	[ -f ../2nd_stage/sbin/$x ] && fn="sbin/$x"
	[ -f ../2nd_stage/usr/bin/$x ] && fn="usr/bin/$x"
	[ -f ../2nd_stage/usr/sbin/$x ] && fn="usr/sbin/$x"

	if [ "$fn" ] ; then
		cp ../2nd_stage/$fn $fn
	else
		echo_error "\`- Program not found: $x"
	fi
done

#

echo_status "Copy the required libraries ..."
found=1 ; while [ $found = 1 ]
do
	found=0
	for x in ../2nd_stage/lib ../2nd_stage/usr/lib
	do
		for y in $( cd $x ; ls *.so.* 2> /dev/null )
		do
			if [ ! -f lib/$y ] &&
			   grep -q $y bin/* lib/* 2> /dev/null
			then
				echo_status "\`- Found $y."
				cp $x/$y lib/$y ; found=1
			fi
		done
	done
done
#
echo_status "Copy linuxrc."
cp ../2nd_stage/linuxrc .
echo_status "Copy /etc/fstab."
cp ../2nd_stage/etc/fstab etc
echo_status "Copy stone.d."
mkdir -p etc/stone.d
for i in gui_text mod_install mod_packages mod_gas default ; do
	cp ../2nd_stage/etc/stone.d/$i.sh etc/stone.d
done
#
echo_status "Creating links for identical files."
while read ck fn
do
	if [ "$oldck" = "$ck" ] ; then
		echo_status "\`- Found $fn -> $oldfn."
		rm $fn ; ln $oldfn $fn
	else
		oldck=$ck ; oldfn=$fn
	fi
done < <( find -type f | xargs md5sum | sort )
#
echo_status "Creating 2nd_stage_small.tar.gz archive."
tar -cf- * | gzip -9 > ../2nd_stage_small.tar.gz ; cd ..

