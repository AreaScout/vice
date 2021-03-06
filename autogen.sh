#! /bin/sh

#
# autogen.sh - generate the auto* files of VICE
#
# Written by
#  Spiro Trikaliotis <spiro.trikaliotis@gmx.de>
#  Marco van den Heuvel <blackystardust68@yahoo.com>
#
# This file is part of VICE, the Versatile Commodore Emulator.
# See README for copyright notice.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#  02111-1307  USA.
#

generate_configure_in() {
	# $1 - major automake version
	# $2 - minor automake version
	# $3 - build

	configure_needs_ac=no
	if [ $1 -gt 1 ]; then
		configure_needs_ac=yes
	else
		if [ $2 -gt 12 ]; then
			configure_needs_ac=yes
		fi
	fi

	if test x"$configure_needs_ac" = "xyes"; then
		sed s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g <configure.proto >configure.ac
	else
		cp configure.proto configure.ac
	fi
}

get_automake_version() {
	# $1 - "automake"
	# $2 - "(GNU"
	# $3 - "Automake)"
	# $4 - version

	automake_version=$4
}

do_command() {
	# $1 - command
	# $2 - options

	echo `pwd`: $1 $2
	$1 $2 > .$1.out 2>&1
	ret=$?
	if [ ! $ret = 0 ] ; then
		echo "ERROR: $1 failed in `pwd`"
		exit 1
	fi
}

do_aclocal() {
	do_command aclocal
}

do_autoconf() {
	do_command autoconf -f
}

do_autoheader() {
	if [ -e configure.in ]; then
		if [ ! x"`sed -ne "s/.*AM_CONFIG_HEADER\((.*)\).*/\1/p" configure.in`" = x ]; then
			do_command autoheader
		fi
	else
		do_command autoheader
	fi
}

do_automake() {
	do_command automake "-a -c" # " -f"
}

buildfiles() {
	FILES_TO_REMEMBER="INSTALL"

	# Save some files which should not be overwritten

	for A in $FILES_TO_REMEMBER; do
		[ -e $A ] && mv $A $A.backup
	done

	do_aclocal

	do_autoconf
	do_autoheader
	do_automake

	# Restore the files which should not be overwritten

	for A in $FILES_TO_REMEMBER; do
		[ -e $A ] && mv $A.backup $A
	done
}

automake_line=`automake --version`
get_automake_version $automake_line
old_IFS=$IFS
IFS="."
generate_configure_in $automake_version
IFS=$old_IFS

SUBDIRECTORIES=`sed -ne "s/.*AC_CONFIG_SUBDIRS(\(.*\)).*/\1/p" configure.ac`

for A in $SUBDIRECTORIES; do
	(
	cd $A
	buildfiles
	)
done

buildfiles

if [ x"$1" = x"--dist" ]; then

	./configure
	(cd src/monitor/; make mon_lex.c mon_parse.c)

	(cd po; make cat-id-tbl.c)

	SVN_ADD_FILES="configure src/config.h.in config.guess config.sub src/monitor/mon_parse.c src/monitor/mon_parse.h src/monitor/mon_lex.c src/resid/depcomp src/resid/mkinstalldirs src/resid/missing src/resid/install-sh doc/texinfo.tex po/cat-id-tbl.c"
	SVN_ADD_MAKEFILES="`find . -name Makefile.in`"

	svn add $SVN_ADD_FILES $SVN_ADD_MAKEFILES

fi
