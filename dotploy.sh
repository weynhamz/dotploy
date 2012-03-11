#!/bin/bash
#
# File: dotploy.sh
#
# Author: Techliv Zheng <techlivezheng at gmail.com>
#
# Usage:
# 	dotploy.sh PATH_TO_THE_DOTFILES_REPO
#
# This is a bash only script designed to help easy the $HOME dot files deployment
# acrossing several hosts. All the hosts share some common dot files. Host specific
# dot files are located under __HOST.$HOSTNAME directory which can overwrite the
# common one with same name.
#
#################################################################################
#
# Copyright (C) 2012 Free Software Foundation.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
##################################################################################

IFS=$'\n'

DOTSREPO=$(realpath $1)

# die if it is not a dotsrepo
[ -f $DOTSREPO/__DOTDIR ] || exit 1

# backup location, categarized by date
BACKUP=$DOTSREPO/__BACKUP/$HOSTNAME/`date +%Y%m%d.%H.%M.%S`

#
# Function: dodeploy
#
# Deploy files
#
# Parameters:
#	$1	directory containing files to be deployed
#	$2	directory where files need to go
#
# This function can be recursive called.
#
dodeploy() {
	local dotdir=$1
	local dstdir=$2

	# recursive identifier
	echo -e "--------\n$dotdir\n--------"

	local filelist=$(ls -1A --color=none $dotdir)

	local file
	for file in $filelist; do
		# skip preserved filenames
		[ "$file" = "__KEEPED" ] && continue
		[ "$file" = "__DOTDIR" ] && continue
		[ "$file" = "__BACKUP" ] && continue
		[ "$file" = "__UNUSED" ] && continue
		[ "$file" = ".git" ] && continue
		echo $file | grep -q  "^__HOST" && continue
		echo $file | grep -q '.swp$' && continue

		if [ -d $dotdir/$file ]; then
			if [ -e $dotdir/$file/__KEEPED ];then
				# this is a directory needed to be keeped,
				# deploy its content.
				dodeploy $dotdir/$file $dstdir/$file
				# recursive identifier
				echo -e "--------\n$dotdir\n--------"
			else
				dosymlink $dotdir $dstdir $file
			fi
		elif [ -f $dotdir/$file ]; then
			dosymlink $dotdir $dstdir $file
		fi
	done
}

#
# Function: dosymlink
#
# Make symlink.
# If destination file existed, backup first.
#
# Parameters:
#	$1	source directory where dotfiles located
#	$2	destination directory of the dotfiles
#	$3	filename of the dotfile
#
dosymlink() {
	local src=$1/$3
	local dst=$2/$3

	# backup existed file
	[ -e $dst ] && \
		echo -en "BACKUP:\t" && \
		local backup=${2#$HOME} && \
		local backup=$BACKUP/${backup#/} && \
		mkdir -vp $backup && \
		mv -v $dst $backup

	# Symlink
	echo -en "SYMLINK:\t" && \
		ln -v -s $src $dst
}

# deploy the public dotfiles
dodeploy $DOTSREPO $HOME

# host based dotfies deploy
if [ -e $DOTSREPO/__HOST.$HOSTNAME ]; then
	list=$(ls -1A $DOTSREPO/__HOST.$HOSTNAME)

	for file in $list; do
		# this is created by the previous deployment, remove it.
		[ -e $DOTSREPO/$file ] && [ -h $HOME/$file ] && rm -v $HOME/$file
	done

	# deploy host based dotfiles
	dodeploy $DOTSREPO/__HOST.$HOSTNAME $HOME
fi
