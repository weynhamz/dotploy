#!/bin/bash
#
# File: dotploy.sh
#
# Author: Techliv Zheng <techlivezheng at gmail.com>
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

# get real user name
USER=$(id -nu)

[[ -z $USER ]] && die "Unkown user"

# get current host name
HOST=$HOSTNAME

[[ -z $HOST ]] && die "Unkown host"

HELP=$(cat << 'EOF'

This script was designed for ease of the dot files deployment under $HOME
directory for mutiple users on several hosts.

Some common dot files are shared by different users and hosts. Host specific
dot files can be placed under __HOST.$HOSTNAME directory, user specific dot
files can be placed under __USER.$USER or __HOST.$HOSTNAME/__USER.$USRE
direcotry. The deeper nested file with same name has a higher priority.

Developed and distributed under GPLv2 or later version.

Usage:

    dotploy.sh [-d] <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]
    dotploy.sh [-p] <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

Options:

    -d  deploy dotfiles
    -p  prune broken symlinks

The <destination_of_the_deployment> is optional. If it is absent, current
$HOME will be used.
EOF
)

# preserved files
IGNORE=(
    "^__USER"
    "^__HOST"
    "^__KEEPED"
    "^__IGNORE"
    "^.git$"
    ".swp$"
)

PRUNE=0
DEPLOY=0
while getopts ":pdh" optname
do
    case "$optname" in
        "p")
            PRUNE=1
        ;;
        "d")
            PRUNE=1
            DEPLOY=1
        ;;
        "h")
            echo "$HELP"
            exit 0
        ;;
        "?")
            echo "ERROR: Unknown option $OPTARG"
            echo "$HELP"
            exit 1
        ;;
    esac
done

shift $((OPTIND - 1))

DOTSHOME=$(realpath $1)
DOTSREPO=$DOTSHOME/__DOTDIR

# die if it is not a dotsrepo
[ -d $DOTSHOME ] && [ -d $DOTSREPO ] || exit 1

DESTHOME=$(realpath ${2:-$HOME})

# make sure our destination is there
[ -d $DESTHOME ] || exit 1

# backup location, categarized by date
BAKPATH=$DOTSHOME/__BACKUP/$HOST/`date +%Y%m%d.%H.%M.%S`

die() {
    echo "$1"
    exit "${2:-1}"
}

#
# Function: doprune
#
# Remove broken symlink according to the last dotploy.log
#
# Parameters:
#   $1  dotploy log file
#
#
doprune() {
    local logfile=$1

    local file
    for file in $(cat $logfile); do
        docheck $file

        [ $? -eq 1 ] && {
            rm -v $file
        }

        [ $DEPLOY -ne 1 ] && [ -e $file ] && echo $file >> $BAKPATH/dotploy.log
    done
}

#
# Function: docheck
#
# Check file status.
#
# Parameters:
#   $1  source directory where dotfiles located
#   $2  destination directory of the dotfiles
#   $3  filename of the dotfile
#
docheck() {
    local src
    local dst=$1
    local repath

    repath=${dst#$DESTHOME}
    repath=${repath#/}

    [ -e $DOTSREPO/$repath ] && src=$DOTSREPO/$repath
    [ -e $DOTSREPO/__USER.$USER/$repath ] && src=$DOTSREPO/__USER.$USER/$repath
    [ -e $DOTSREPO/__HOST.$HOST/$repath ] && src=$DOTSREPO/__HOST.$HOST/$repath
    [ -e $DOTSREPO/__HOST.$HOST/__USER.$USER/$repath ] && src=$DOTSREPO/__HOST.$HOST/__USER.$USER/$repath

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
        if [ -f $src/__KEEPED ];then
            #if dst is a dir,should check whether it contains high lever files
            return 4
        else
            #need backup
            return 2
        fi
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
#   $1  directory containing files to be deployed
#   $2  directory where files need to go
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
            local line
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

        grep "^$dstdir/$file\$" $BAKPATH/dotploy.log >/dev/null 2>&1

        [ $? -ne 0 ] && echo "$dstdir/$file" >> $BAKPATH/dotploy.log
    done
}

#
# Function: dosymlink
#
# Make symlink.
# If destination file existed, backup first.
#
# Parameters:
#   $1  source directory where dotfiles located
#   $2  destination directory of the dotfiles
#   $3  filename of the dotfile
#
dosymlink() {
    local src=$1/$3
    local dst=$2/$3

    local repath

    repath=${1#$DOTSREPO}
    repath=${repath#/}
    repath=${repath#__HOST.$HOST}
    repath=${repath#/}
    repath=${repath#__USER.$USER}
    repath=${repath#/}

    # for nested path, need to mkdir parent first
    [ -n "$repath" ] && {
        mkdir -vp $DESTHOME/$repath
    }

    docheck $dst

    local status=$?

    [ $status -eq 1 ] && {
        rm -v $dst
    }

    # backup existed file
    [ $status -eq 2 ] && {
        echo -en "BACKUP:\t"
        mkdir -vp $BAKPATH/$repath && mv -v $dst $BAKPATH/$repath
    }

    # Symlink
    [ $status -ne 0 ] && [ $status -ne 4 ] && {
        echo -en "SYMLINK:\t"
        ln -v -s $src $dst
    }
}

mkdir -vp $BAKPATH || exit 1

echo $DESTHOME > $BAKPATH/DESTHOME

touch $BAKPATH/dotploy.log

if [ $PRUNE -eq 1 ];then
    for logpath in $(grep -l "^$DESTHOME\$" $DOTSHOME/__BACKUP/$HOST/*/DESTHOME | tail -2 | sed 's-/DESTHOME$--g');do
        [ "$logpath" = "$BAKPATH" ] && continue

        [ -f $logpath/dotploy.log ] && doprune $logpath/dotploy.log
    done
fi

if [ $DEPLOY -eq 1 ];then
    # host user based dotfies deploy
    [ -e $DOTSREPO/__HOST.$HOST/__USER.$USER ] && \
        dodeploy $DOTSREPO/__HOST.$HOST/__USER.$USER $DESTHOME

    # host based dotfies deploy
    [ -e $DOTSREPO/__HOST.$HOST ] && \
        dodeploy $DOTSREPO/__HOST.$HOST $DESTHOME

    # user based dotfies deploy
    [ -e $DOTSREPO/__USER.$USER ] && \
        dodeploy $DOTSREPO/__USER.$USER $DESTHOME

    dodeploy $DOTSREPO $DESTHOME
fi
