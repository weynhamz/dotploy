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

# Function: _abspath
#
#    Get the absolute path for a file
#
#    From: http://stackoverflow.com/questions/59895
#
_abspath() {
    local path=${1:-$(caller | cut -d' ' -f2)}
    local path_dir=$( dirname "$path" )
    while [ -h "$path" ]
    do
        path=$(readlink "$path")
        [[ $path != /* ]] && path=$path_dir/$path
        path_dir=$( cd -P "$( dirname "$path"  )" && pwd )
    done
    path_dir=$( cd -P "$( dirname "$path" )" && pwd )
    echo "$path_dir"
}

ABSPATH=$(_abspath)

if [[ -f $ABSPATH/../../libs/bashLib/src/bashLib ]]
then
    source "$ABSPATH/../../libs/bashLib/src/bashLib"
elif [[ -f $ABSPATH/bundles/bashLib/src/bashLib ]]
then
    source "$ABSPATH/bundles/bashLib/src/bashLib"
elif [[ -f /usr/share/dotploy/bundles/bashLib/bashLib ]]
then
    source "/usr/share/dotploy/bundles/bashLib/bashLib"
elif [[ -f /usr/share/lib/bashLib/bashLib ]]
then
    source "/usr/share/lib/bashLib/bashLib"
else
    echo "Can not find bashLib, you need to install it as bundles first."
    exit 1
fi

###############################################################################
#
# Main Program
#
###############################################################################

ABSPATH=$(_abspath)

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

print() {
    [ $VERBOSE -eq 1 ] && [ -n "$1" ] && echo "$1" | sed "s/^/$(printf '|%.0s' $(seq 1 $DEPTH))\t/g"
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
            print $'UPDATE:\t'"$file"
            print "$(rm -v $file)"
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

    DEPTH=$(( $DEPTH + 1 ))
    print $'ENTER:\t'"$dotdir"

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
            else
                dosymlink $dotdir $dstdir $file
            fi
        elif [ -f $dotdir/$file ]; then
            dosymlink $dotdir $dstdir $file
        fi

        grep "^$dstdir/$file\$" $LOGFILE >/dev/null 2>&1

        [ $? -ne 0 ] && echo "$dstdir/$file" >> $LOGFILE
    done

    print $'LEAVE:\t'"$dotdir"
    DEPTH=$(( $DEPTH - 1 ))
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
            print $'BACKUP:\t'"$DESTHOME/$repath"
            DEPTH=$(( $DEPTH + 1 ))
            print "$(mkdir -vp $BAKPATH/$(dirname "$repath") && mv -v $DESTHOME/$repath $BAKPATH/$(dirname "$repath"))"
            DEPTH=$(( $DEPTH - 1 ))
        }
        print $'MKDIR:\t'"$DESTHOME/$repath"
        DEPTH=$(( $DEPTH + 1 ))
        print "$(mkdir -vp $DESTHOME/$repath)"
        DEPTH=$(( $DEPTH - 1 ))
    }

    docheck $dst

    local status=$?

    # remove broken link
    [ $status -eq 1 ] && {
        print $'REMOVE:\t'"$dst"
        DEPTH=$(( $DEPTH + 1 ))
        print "$(rm -v $dst)"
        DEPTH=$(( $DEPTH - 1 ))
    }

    # backup existed file
    [ $status -eq 2 ] && {
        print $'BACKUP:\t'"$dst"
        DEPTH=$(( $DEPTH + 1 ))
        print "$(mkdir -vp $BAKPATH/$repath && mv -v $dst $BAKPATH/$repath)"
        DEPTH=$(( $DEPTH - 1 ))
    }

    # symlink the file in the repo
    [ $status -ne 0 ] && [ $status -ne 4 ] && {
        print $'SYMLINK:\t'"$dst"
        DEPTH=$(( $DEPTH + 1 ))
        print "$(ln -v -s $src $dst)"
        DEPTH=$(( $DEPTH - 1 ))
    }
}

show_help() {
    cat << 'EOF'

Usage:

    dotploy.sh <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

Options:

    -h, show help information
    -v, be verbose about the process
The argument `<destination_of_the_deployment>` is optional. If it is absent,
then current `$HOME` directory will be used.

Conflicted files will be backed up into `.dotploy/` directory under your
deployment destination.

EOF
}

declare -a args
declare -i DEPTH=0
declare -i VERBOSE=0
while [ $# -gt 0 ]
do
    case "$1" in
        -p )
            echo "Option '-p' has been depreciated"
            show_help
            exit 1
        ;;
        -d )
            echo "Option '-d' has been depreciated"
            show_help
            exit 1
        ;;
        -v | --verbose )
            VERBOSE=1
        ;;
        -h | --help )
            show_help
            exit 0
        ;;
        -* )
            echo "ERROR: Unknown option $1"
            show_help
            exit 1
        ;;
        * )
            args+=("$1")
        ;;
    esac
    shift
done

set -- "${args[@]}"

DOTSHOME=$(realpath $1)
DOTSREPO=$DOTSHOME/__DOTDIR

# die if it is not a dotsrepo
[ -d $DOTSHOME ] && [ -d $DOTSREPO ] || die "$DOTSREPO is not available"

DESTHOME=$(realpath ${2:-$HOME})

# make sure our destination is there
[ -d $DESTHOME ] || die "$DESTHOME is not available"

CONFDIR=$DESTHOME/.dotploy

mkdir -p $CONFDIR || exit 1

# backup location, categarized by date
BAKPATH=$CONFDIR/backup/`date +%Y%m%d.%H.%M.%S`

# keep a record of the deployed files
LOGFILE=$CONFDIR/filelog

# transform old backup sctruction to the new one
[ -d $DOTSHOME/__BACKUP/$HOST ] && {
    echo "Performing transition ..."

    [ -f $LOGFILE ] && mv $LOGFILE $LOGFILE.bak
    for bakpath in $(grep -l "^$DESTHOME\$" $DOTSHOME/__BACKUP/$HOST/*/DESTHOME | sed 's-/DESTHOME$--g');do
        mv $bakpath/dotploy.log $LOGFILE &>/dev/null

        [ -f $bakpath/dotploy.log ] && {
            echo error
            continue
        }

        rm $bakpath/DESTHOME &>/dev/null

        [ -f $bakpath/DESTHOME ] && {
            echo error
            continue
        }

        rmdir $bakpath &> /dev/null || mv $bakpath $CONFDIR/backup
    done
    [ -f $LOGFILE.bak ] && mv $LOGFILE.bak $LOGFILE

    rmdir --ignore-fail-on-non-empty -p $DOTSHOME/__BACKUP/$HOST

    echo "Transition done."
}

if [ -f $LOGFILE ];then
    doprune $LOGFILE
fi

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
