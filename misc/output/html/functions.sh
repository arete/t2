# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/misc/output/html/functions.sh
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

mkdir -p $ROCKCFG_OUTPUT_HTML_DIR

html_color_normal=000000
html_color_error=ff5552
html_color_status=52ff52
html_color_header=ff55ff

echo_html_raw() {
	echo -n "$*" >> $ROCKCFG_OUTPUT_HTML_DIR/index.html
}

echo_html_text() {
	echo -n "<tt><font color=$1>$2</font></tt>" >> $ROCKCFG_OUTPUT_HTML_DIR/index.html
}

echo_html_newline() {
	echo "&nbsp;<br>" >> $ROCKCFG_OUTPUT_HTML_DIR/index.html
}

echo_header_html() {
	echo_html_newline
	echo_html_text ${html_color_header} "$*"
	echo_html_newline
}

echo_status_html() {
	echo_html_text ${html_color_status} "-> "
	echo_html_text ${html_color_normal} "$*"
	echo_html_newline
}

echo_error_html() {
	echo_html_text ${html_color_error} "!> $*"
	echo_html_newline
}

echo_pkg_deny_html() {
	echo_html_newline
	echo_html_text ${html_color_error} "$( date "+== %D %T =[$1]=> Package $2 $3." )"
	echo_html_newline
}

echo_pkg_start_html() {
	echo_html_newline
	echo_html_text ${html_color_header} "$( date "+== %T =[$1]=> Building $2/$3 [$4 $5]." )"
	echo_html_newline
}

echo_pkg_finish_html() {
	echo_html_text ${html_color_header} "$( date "+== %D %T =[$1]=> Finished building package $3." )"
	# local tm=$( date '+%s' )
	# cp $root/var/adm/logs/$1-$3.log $ROCKCFG_OUTPUT_HTML_DIR/$1-$3-$tm.txt
	# echo_html_raw " &nbsp; <b>[<a href=\"$1-$3-$tm.txt\">logfile</a>]</b>"
	echo_html_newline
}

echo_pkg_abort_html() {
	echo_html_text ${html_color_error} "$( date "+== %D %T =[$1]=> Aborted building package $3." )"
	# local tm=$( date '+%s' )
	# cp $root/var/adm/logs/$1-$3.err $ROCKCFG_OUTPUT_HTML_DIR/$1-$3-$tm.txt
	# echo_html_raw " &nbsp; <b>[<a href=\"$1-$3-$tm.txt\">logfile</a>]</b>"
	echo_html_newline
}

echo_errorquote_html() {
	echo "$*" | grep . | while read line; do
		echo_html_text ${html_color_error} "!> "
		echo_html_text ${html_color_normal} "$line"
		echo_html_newline
	done
}

