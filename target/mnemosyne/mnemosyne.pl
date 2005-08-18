#!/usr/bin/perl
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/mnemosyne/mnemosyne.pl
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

use warnings;
use strict;
use IPC::Open2;

use constant {ALL => 0, ASK => 1, CHOICE => 2 };
%::FOLDER=();
%::MODULE=();

sub scandir {
	my ($pkgseldir,$prefix) = @_;
	my %current=('location', $pkgseldir, 'var', "CFGTEMP_$prefix");

	# $current{desc,var} for sub-pkgsel dirs
	if ($pkgseldir ne $::ROOT) {
		my ($relative,$dirvar,$dirname);
		$_ = $pkgseldir;
		$relative = (m/^$::ROOT\/(.*)/i)[0];

		$dirvar =  "CFGTEMP_$prefix\_$relative";
		$dirvar =~ tr,a-z\/,A-Z_,;

		$dirname=$relative;
		$dirname=~ s/.*\///g;

		$current{desc} = $dirname;
		$current{var}  = $dirvar;
	}

	# make this folder global
	$::FOLDER{$current{var}} = \%current;

	{
	# make scandir recursive
	my @subdirs;
	opendir(my $DIR, $pkgseldir);
	foreach( grep { ! /^\./ } sort readdir($DIR) ) {
		$_ = "$pkgseldir/$_";
		if ( -d $_ ) {
			my $subdir = scandir($_,$prefix);
			push @subdirs,$subdir;
		} else {
			scanmodule($_,$prefix);
		}
	}
        closedir $DIR;
	$current{subdirs} = \@subdirs;
	return $current{var};
	}

}

sub scanmodule {
	my ($file,$prefix)=@_;
	my (%current,$FILE);

	# this defines dir,key,option and kind acording to the following format.
	# $dir/[$prio-]$var[$option].$kind
	do {
		my ($dir,$key,$option,$kind);
		m/^(.*)\/(\d+-)?([^\.]*).?([^\.]*)?\.([^\/\.]*)/i;
		($dir,$key,$option,$kind) = ($1,$3,$4,$5);

		if ($kind eq 'choice') { $current{kind} = CHOICE; $current{option} = $option; }
		elsif ($kind eq 'all') { $current{kind} = ALL; }
		elsif ($kind eq 'ask') { $current{kind} = ASK; }
		else { return; }

		$current{location} = $dir;
		$current{key} = $key;
		$current{file} = $file;
	
	} for $file;

	open($FILE,'<',$file);
	while(<$FILE>) {
		if (/^#[^#: ]+: /) {
			my ($field,$value) = m/^#([^#: ]+): (.*)$/i;
			if ($field eq 'Description') {
				$current{desc} = $value;
			} elsif ($field eq 'Variable') {
				$current{var} = $value;
			} elsif ($field eq 'Default') {
				$current{default} = $value;
			} elsif ($field eq 'Forced') {
				$current{forced} = $value;
			} elsif ($field eq 'Imply') {
				$current{imply} = $value;
			} elsif ($field eq 'Dependencies') {
				$current{deps} = $value;
		#	} else {
		#		print "$file:$field:$value.\n";
				}
			}
		}
	close($FILE);

	# var name
	$current{var} = uc $current{key}
		unless exists $current{var};
	$current{var} = "SDECFG_$prefix\_" . $current{var}
		unless $current{var} =~ /^SDECFG_$prefix\_/;

	# for choices, we use $option instead of $key as description
	($current{desc} = $current{option}) =~ s/_/ /g
		if exists $current{option} && ! exists $current{desc};
	($current{desc} = $current{key}) =~ s/_/ /g
		unless exists $current{desc};

	# dependencies
	# NOTE: don't use spaces on the pkgsel file, only to delimite different dependencies
	if (exists $current{deps}) {
		my @deps;
		for ( split (/\s+/,$current{deps}) ) {
			$_="SDECFG_$prefix\_$_" unless /^SDECFG/;

			if (/=/) {
				m/(.*)(==|!=|=)(.*)/i;
				$_="\"\$$1\" $2 $3";
			} else {
				$_="\"\$$_\" == 1";
				}

			push @deps,$_;
			}
		$current{deps} = \@deps;
		}

	# forced modules
	if (exists $current{forced}) {
		my @forced;
		for ( split (/\s+/,$current{forced}) ) {
			$_="SDECFG_$prefix\_$_" unless /^SDECFG/;

			$_="$_=1" unless /=/;
			push @forced,$_;
			}
		$current{forced} = \@forced;
		}
	
	# implied options
	if (exists $current{imply}) {
		my @imply = split (/\s+/,$current{imply});
		$current{imply} = \@imply;
		}

	# make this module global
	if ( $current{kind} == CHOICE ) {

		# prepare the option for this choice
		my %option;
		for ('desc','forced','imply','deps','option','file') {
			$option{$_}=$current{$_} if exists $current{$_};
			}

		if ( exists $::MODULE{$current{var}} ) {
			push @{ $::MODULE{$current{var}}{options} },\%option;
		} else {
			# prepare and add this choice module
			my @options = (\%option);

			$::MODULE{$current{var}} = {
				'kind', CHOICE,
				'options', \@options,
				};

			for ('key','location','var') {
				$::MODULE{$current{var}}{$_}=$current{$_}
					if exists $current{$_};
				}
			}

	} else {
		$::MODULE{$current{var}} = {};
		for ('key','location','var','desc','forced','deps','file','kind') {
			$::MODULE{$current{var}}{$_}=$current{$_}
				if exists $current{$_};
			}
		}

	# default value
	$::MODULE{$current{var}}{default} = $current{default} 
		if exists $current{default};

	}
	
sub process_modules { 
	my ($READ,$WRITE);

	open2($READ, $WRITE, 'tsort');
	# prepare topographic modules map
	for my $module (values %::MODULE) { 
		print $WRITE "$module->{var}\n";
		for (@{exists $module->{deps} ? $module->{deps} : []} ) {
			my $dep = (m/"\$([^"]+)"/i)[0];
			print $WRITE "$dep $module->{var}\n";
			}
		for (@{exists $module->{forced} ? $module->{forced} : []} ) {
			my $forced = (m/([^"]+)=/i)[0];
			print $WRITE "$module->{var} $forced\n";
			}
		}
	close($WRITE);

	# and populate the sorted list
	my @sorted;
	while(<$READ>) {
		if (/(.*)\n/) { push @sorted, $1; }
		}

	# and remember the sorted list
	$::MODULES=\@sorted;
}

sub process_folders { 
	my ($READ,$WRITE);

	open2($READ, $WRITE, 'tsort | tac');
	# prepare topographic modules map
	for my $folder (values %::FOLDER) { 
		for (@{exists $folder->{subdirs} ? $folder->{subdirs} : []} ) {
			print $WRITE "$folder->{var} $_\n";
			}
		}
	close($WRITE);

	# and populate the sorted list
	my @sorted;
	while(<$READ>) {
		if (/(.*)\n/) { push @sorted, $1; }
		}

	# and remember the sorted list
	$::FOLDERS=\@sorted;
}

sub render_widgets {
	open(my $FILE,'<',$_[0]);
	close($FILE);
	}
	
sub render_rules_module {
	my ($module,$offset,$pkgsellist) = @_;
	my $var    = $module->{var};

	if ($module->{kind} == CHOICE) {
		my $tmpvar = "CFGTEMP_$1" if $var =~ m/^SDECFG_(.*)/i;
		my $listvar = "$tmpvar\_LIST";

		# initialize the list
		print "${offset}$listvar=\n";
		print "${offset}$tmpvar=\" \"\n";

		for ( @{ $module->{options} } ) {
			my $option = $_;
			(my $desc = $option->{desc}) =~ s/ /_/g;

			if (exists $option->{deps}) {
				print "${offset}if [ " .
					join(' -a ', @{ $option->{deps} } ) .
					" ]; then\n";
				print "${offset}\t$listvar=\"\$$listvar $option->{option} $desc\"\n";
				print "${offset}\t$tmpvar=\"\${$tmpvar}$option->{option} \"\n"; 
				print "${offset}fi\n";
			} else {
				print "\n${offset}$listvar=\"\$$listvar $option->{option} $desc\"\n";
				print "${offset}$tmpvar=\"\${$tmpvar}$option->{option} \"\n"; 
				}
			}

		print "\n";
		if (exists $module->{default}) {
			print "${offset}if [ \"\${$tmpvar// \$$var /}\" == \"\$$tmpvar\" ]; then\n";
			print "${offset}\t$var=$module->{default}\n";
			print "${offset}fi\n";
			}
		print "${offset}if [ \"\${$tmpvar// \$$var /}\" == \"\$$tmpvar\" ]; then\n";
		print "$offset\t$var=`echo \"\$$tmpvar\" | cut -d' ' -f2`\n";
		print "${offset}fi\n";
		
	#	printref($var,$module,$offset);
	} elsif ($module->{kind} == ASK) {
		my $default=0;
		$default = $module->{default} if exists $module->{default};

		# and set the default value if none is set.
		print "$offset\[ -n \"\$$var\" \] || $var=$default\n";

		# if enabled, append pkgsel and force the forced
		print "\n${offset}if [ \"\$$var\" == 1 ]; then\n";

		if (exists $module->{forced}) {
			for ( @{ $module->{forced} } ) {
				print "$offset\t$_\n";
				print "$offset\tSDECFGSET_$1\n" if $_ =~ m/^SDECFG_(.*)/i;
				}
			}
		print "$offset\t$pkgsellist=\"\$$pkgsellist $module->{file}\"\n";

		print $offset."fi\n";
	} else {
		# just enable the feature
		print "$offset$var=1\n";
		print "$pkgsellist=\"\$$pkgsellist $module->{file}\"\n";

		# forced list doesn't make sense for {kind} == ALL
		}

	}
sub render_rules_nomodule {
	my ($module,$offset) = @_;
	my $var = $module->{var};

	# unset the choice list, and the var
	if ($module->{kind} == CHOICE) {
		my $tmpvar = "CFGTEMP_$1" if $var =~ m/^SDECFG_(.*)/i;
		print "${offset}unset $tmpvar\n";
		}
	print "${offset}unset SDECFGSET_$1\n" if $var =~ m/^SDECFG_(.*)/i;
	print "${offset}unset $var\n";
	}

sub render_rules {
	open(my $FILE,'<',$_[0]);

	# pkgsel list
	my $pkgsellist = "CFGTEMP_$_[1]_PKGLIST";
	print "$pkgsellist=\n";

	for (@$::MODULES) {
		my $module = $::MODULE{$_};
		print "\n#\n# $module->{var} ("
			. ($module->{kind} == ALL ? "ALL" : ($module->{kind} == ASK ? "ASK" : "CHOICE" ) )
			.  ")\n#\n";

		
		if (exists $module->{deps}) {
			print "if [ " . join(' -a ', @{ $module->{deps} } ) . " ]; then\n";
			render_rules_module($module,"\t",$pkgsellist);
			print "else\n";
			render_rules_nomodule($module,"\t");
			print "fi\n";
		} else {
			render_rules_module($module,"",$pkgsellist);
			}
		}
#	for (@$::FOLDERS) {
#		my $folder = %{ $::FOLDER{$_} };
#		}
	close($FILE);
	}
	
sub trg_mnemosyne_filter {
=for comment
	echo "# generated for $SDECFG_TARGET target"
	pkgsel_init
	echo '{ $1="O"; }'
	for file; do
		pkgsel_parse < $file
	done
	pkgsel_finish
=cut
}

# print the content of a hash
sub printref {
	my ($name,$ref,$offset) = @_;
	my $typeof = ref($ref);

	print "$offset$name:";
	if ($typeof eq '') {
		print " '$ref'\n";
	} elsif ($typeof eq 'HASH') {
		print "\n";
		for (sort keys %{ $ref }) {
			printref($_,$ref->{$_},"$offset\t");
			}
	} elsif ($typeof eq 'ARRAY') {
		my $i=0;
		print "\n";
		for (@{ $ref }) {
			printref("[$i]",$_,"$offset\t");
			$i++;
		}
	} else {
		print " -> $typeof\n";
		}
}

if ($#ARGV != 3) {
	print "Usage mnemosyne.pl: <pkgseldir> <prefix> <configfile> <rulesfile>\n";
	exit (1);
	}

$::ROOT=$ARGV[0];
scandir($ARGV[0],$ARGV[1]);
process_modules();
process_folders();
render_rules($ARGV[3],$ARGV[1]);
render_widgets($ARGV[2]);
#printref('%::MODULE',\%::MODULE,'');
