# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/*/bdb40/bdb_config.sh
# Copyright (C) 1998 - 2003 ROCK Linux Project
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

hook_add preconf 2 'cd build_unix'
configscript="../dist/configure"

var_append confopt ' ' '--enable-compat185'
var_append confopt ' ' '--enable-cxx'
var_append confopt ' ' "--includedir=$root/$prefix/include/db${ver:0:1}"

# we need the install-sh here, since our gnu-install does not
# handle the transform-name ...
var_append confopt ' ' "--program-transform-name='s/db/db${ver:0:1}/'"

# bdb doesn't like some of our make options
makeopt="docdir=$docdir all" ; makeinstopt="docdir=$docdir install"

hook_add postinstall 8 'chmod 755 $libdir/libdb-${ver:0:3}.so \
	$libdir/libdb_cxx-${ver:0:3}.so'

# create yet another alternative library name some programs use
# this will crate a symlink in the form libdb-4.1.so -> libdb41.so
hook_add postinstall 9 'ln -sfv libdb-${ver:0:3}.so $libdir/libdb${ver:0:1}.so'

# bdb does copy the docs itself ...
createdocs=0

