#!/bin/bash
#
# File: dotploy.sh
#
# Author: Techliv Zheng <techlivezheng at gmail.com>
#
# Usage:
# 	dotploy.sh PATH_TO_THE_DOTFILES_REPO [DESTINATION_OF_THE_DOT_FILES]
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

DOTSHOME=$(realpath $1)
DOTSREPO=$DOTSHOME/__DOTDIR
[ -n "$2" ] && DESTHOME=$(realpath $2) || DESTHOME=$HOME

# die if it is not a dotsrepo
[ -d $DOTSHOME ] && [ -d $DOTSREPO ] || exit 1

# backup location, categarized by date
BACKUP=$DOTSHOME/__BACKUP/$HOSTNAME/`date +%Y%m%d.%H.%M.%S`

# preserved files
IGNORE=(
	"^__HOST"
	"^__KEEPED"
	"^__IGNORE"
	"^.git$"
	".swp$"
)
#
# Function: docheck
#
# Check file status.
#
# Parameters:
#	$1	source directory where dotfiles located
#	$2	destination directory of the dotfiles
#	$3	filename of the dotfile
#
docheck() {
	local src
	local dst=$1
	local repath

	repath=${dst#$DESTHOME}
	repath=${repath#/}

	[ -e $DOTSREPO/$repath ] && src=$DOTSREPO/$repath
	[ -e $DOTSREPO/__HOST.$HOSTNAME/$repath ] && src=$DOTSREPO/__HOST.$HOSTNAME/$repath

	echo "CHECKING: $dst"

	if [ -h $dst ];then
	    local csrc=$(readlink -fm $dst)

		if [[ $csrc =~ $DOTSHOME ]];then #whether link to dotsrepo
			if [ "$csrc" == "$src" ];then
				#all good
				return 0
			else
				#need update
				return 1
			fi
		else
			#need backup
			return 2
		fi
	elif [ -d $dst ];then
		[ -f $src/__KEEPED ] && \
			#if dst is a dir,should check whether it contains high lever files
			return 4 || \
			#need backup
			return 2
	elif [ -f $dst ];then
		#need backup
		return 2
	else
		#not existed, do link
		return 3
	fi
}

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

	# need to check the src,make sure it is a direcotry
	docheck $dstdir

	local status=$?

	[ $status -eq 0 ] && return

	[ $status -eq 1 ] && rm -v $dstdir

	# host based dotfies deploy
	[ -e $dotdir/__HOST.$HOSTNAME ] && \
		dodeploy $dotdir/__HOST.$HOSTNAME $dstdir

	# recursive identifier
	echo -e "--------\n$dotdir\n--------"

	local filelist=$(ls -1A --color=none $dotdir)

	local file
	for file in $filelist; do
		# skip preserved filenames
		local line
		for line in ${IGNORE[@]};do
			[[ $file =~ $line ]] && continue 2
		done
		if [ -f $dotdir/__IGNORE ]; then
			for line in $(cat $dotdir/__IGNORE);do
				[[ $file =~ $line ]] && continue 2
			done
		fi

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

	local repath

	repath=${1#$DOTSREPO}
	repath=${repath#/}
	repath=${repath#__HOST.$HOSTNAME}
	repath=${repath#/}

	# for nested path, need to mkdir parent first
	[ -n "$repath" ] && mkdir -vp $DESTHOME/$repath

	docheck $dst

	local status=$?

	[ $status -eq 1 ] && \
		rm -v $dst

	# backup existed file
	[ $status -eq 2 ] && \
		echo -en "BACKUP:\t" && \
		local backup=$BACKUP/$repath && \
		mkdir -vp $backup && \
		mv -v $dst $backup

	# Symlink
	[ $status -ne 0 ] && [ $status -ne 4 ] && \
		echo -en "SYMLINK:\t" && \
		ln -v -s $src $dst
}

dodeploy $DOTSREPO $DESTHOME
