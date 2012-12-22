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
#################################################################################

IFS=$'\n'

# get real user name
USER=$(id -nu)

[[ -z $USER ]] && die "Unkown user"

# get current host name
HOST=$HOSTNAME

[[ -z $HOST ]] && die "Unkown host"

# preserved files
IGNORE=(
    "^__USER"
    "^__HOST"
    "^__KEEPED"
    "^__IGNORE"
    "^.git$"
    ".swp$"
)

die() {
    echo "$1"
    exit "${2:-1}"
}

#
# Function: doprune
#
# Remove broken symlinks
#
# Parameters:
#   $1  log file recorded the deployed symlinks
#
doprune() {
    local logfile=$1

    local file
    for file in $(cat $logfile); do
        docheck $file

        [ $? -eq 1 ] && {
            rm -v $file
        }
    done
}

#
# Function: docheck
#
# Check the status of a given file
#
# Parameters:
#   $1  target file to be checked
#
# Return Value:
#   0 all good
#   1 need update
#   2 need backup
#   3 not existed, do link
#   4 do nothing, deploy its contents
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

        if [[ $csrc =~ $DOTSHOME ]];then
            if [ "$csrc" == "$src" ];then
                return 0
            else
                return 1
            fi
        else
            return 2
        fi
    elif [ -d $dst ];then
        if [ -f $src/__KEEPED ];then
            return 4
        else
            return 2
        fi
    elif [ -f $dst ];then
        return 2
    else
        return 3
    fi
}

#
# Function: dodeploy
#
# Deploy files
#
# Parameters:
#   $1  directory containing dot files
#   $2  directory where files need to go
#
# This function can be called recursively.
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
        local line
        for line in ${IGNORE[@]};do
            [[ $file =~ $line ]] && continue 2
        done

        # apply user-defined ignoring rules
        if [ -f $dotdir/__IGNORE ]; then
            local line
            for line in $(cat $dotdir/__IGNORE);do
                [[ $file =~ $line ]] && continue 2
            done
        fi

        if [ -d $dotdir/$file ]; then
            if [ -e $dotdir/$file/__KEEPED ];then
                # this directory needs to be kept,
                # deploy its contents.
                dodeploy $dotdir/$file $dstdir/$file
                # recursive identifier
                echo -e "--------\n$dotdir\n--------"
            else
                dosymlink $dotdir $dstdir $file
            fi
        elif [ -f $dotdir/$file ]; then
            dosymlink $dotdir $dstdir $file
        fi

        grep "^$dstdir/$file\$" $LOGFILE >/dev/null 2>&1

        [ $? -ne 0 ] && echo "$dstdir/$file" >> $LOGFILE
    done
}

#
# Function: dosymlink
#
# Make a symlink.
#
# If the target file exists, backup it first.
#
# Parameters:
#   $1  source directory where the dotfile is located
#   $2  target directory where the dotfile will be deployed
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
        # backup if the target already exits
        [ -f "$DESTHOME/$repath" ] && {
            mkdir -vp $BAKPATH/$(dirname "$repath") && mv -v $DESTHOME/$repath $BAKPATH/$(dirname "$repath")
        }
        mkdir -vp $DESTHOME/$repath
    }

    docheck $dst

    local status=$?

    # remove broken link
    [ $status -eq 1 ] && {
        rm -v $dst
    }

    # backup existed file
    [ $status -eq 2 ] && {
        echo -en "BACKUP:\t"
        mkdir -vp $BAKPATH/$repath && mv -v $dst $BAKPATH/$repath
    }

    # symlink the file in the repo
    [ $status -ne 0 ] && [ $status -ne 4 ] && {
        echo -en "SYMLINK:\t"
        ln -v -s $src $dst
    }
}

show_help() {
    cat << 'EOF'

This script is designed for ease of deploying the dot files under $HOME
directory for mutiple users on several hosts.

Common dot files need to be shared with different users on different hosts
could be placed in the root directory of the dots repo.  While host specific
dot files could be placed under `__HOST.$HOSTNAME` directory, and user specific
dot files be placed under `__USER.$USER` or `__HOST.$HOSTNAME/__USER.$USRE`
direcotry. The file in the specified host or user directory with same name
has higher priority.

This script is developed and distributed under GPLv2 or later version.

Usage:

    dotploy.sh <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

The `<destination_of_the_deployment>` is optional. If absent, current `$HOME`
directory will be used.

EOF
}

while getopts ":pdh" optname
do
    case "$optname" in
        "p")
            echo "Option '-p' has been depreciated"
            show_help
            exit 1
        ;;
        "d")
            echo "Option '-d' has been depreciated"
            show_help
            exit 1
        ;;
        "h")
            show_help
            exit 0
        ;;
        "?")
            echo "ERROR: Unknown option $OPTARG"
            show_help
            exit 1
        ;;
    esac
done

shift $((OPTIND - 1))

DOTSHOME=$(realpath $1)
DOTSREPO=$DOTSHOME/__DOTDIR

# die if it is not a dotsrepo
[ -d $DOTSHOME ] && [ -d $DOTSREPO ] || die "$DOTSREPO is not available"

DESTHOME=$(realpath ${2:-$HOME})

# make sure our destination is there
[ -d $DESTHOME ] || die "$DESTHOME is not available"

# backup location, categarized by date
BAKPATH=$DOTSHOME/__BACKUP/$HOST/`date +%Y%m%d.%H.%M.%S`

mkdir -vp $BAKPATH || exit 1

# used to identify where our backup came from
echo $DESTHOME > $BAKPATH/DESTHOME

# keep a record of the deployed files
LOGFILE=$BAKPATH/dotploy.log

touch $LOGFILE

# remove the broken symlinks since last deployment first
for logpath in $(grep -l "^$DESTHOME\$" $DOTSHOME/__BACKUP/$HOST/*/DESTHOME | tail -2 | sed 's-/DESTHOME$--g');do
    [ "$logpath" = "$BAKPATH" ] && continue

    [ -f $logpath/dotploy.log ] && doprune $logpath/dotploy.log
done

# host user based dotfies deploy
[ -d $DOTSREPO/__HOST.$HOST/__USER.$USER ] && \
    dodeploy $DOTSREPO/__HOST.$HOST/__USER.$USER $DESTHOME

# host based dotfies deploy
[ -d $DOTSREPO/__HOST.$HOST ] && \
    dodeploy $DOTSREPO/__HOST.$HOST $DESTHOME

# user based dotfies deploy
[ -d $DOTSREPO/__USER.$USER ] && \
    dodeploy $DOTSREPO/__USER.$USER $DESTHOME

# shared dotfiles deploy
dodeploy $DOTSREPO $DESTHOME
