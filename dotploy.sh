#!/bin/bash
#
# File: dotploy.sh
#
# Author: Techlive Zheng <techlivezheng at gmail.com>
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

# @@BASHLIB BEGIN@@

# Function: _abspath
#
#    Get the absolute path for a file
#
#    From: http://stackoverflow.com/questions/59895
#
_abspath() {
    local path=${1:-$(caller | cut -d' ' -f2)}
    local path_dir=$( dirname "$path" )
    while [[ -h "$path" ]]
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

# @@BASHLIB END@@

# Function: die
#
#    Show an error message and exit
#
# Arguments:
#
#    $1: message to show
#    $2: exit value
#
die() {
  echo_error "$1" >&2
  exit "${2:-1}"
}

# Function: in_array
#
#    Whether an elememt belongs to an array
#
# Arguments:
#
#    $1: element to check
#
in_array() {
  local e
  for e in "${@:2}"; do [[ $e == $1 ]] && return 0; done
  return 1
}

# Function: interactive_select
#
#    Wrapper function to construct a selection menu
#
# Arguments:
#
#    $1: variable name where the result to be assigned
#    $2: variable name of an associative array where the
#        readable information for the item comes from
#    $3: prompt message shown at the begining
#    $-: the rest arguments are the items for selection,
#        also the keys for the associative array of $2
#
# option, options, result, source, prompt, arguments, arguments_count is preserved for variable name
interactive_select() {
  local refvar
  local option
  local options
  local result=$1 && shift
  local source=$1 && shift
  local prompt=$1 && shift
  local arguments=("$@")
  local arguments_count=$#

  # if the variable name of the associative array which
  # stores the readable infomation for the items is given,
  # then we translate all the positional parameters to their
  # readable form.
  [[ -n $source ]] && {
    declare -a options
    while [ $# -gt 0 ]
    do
      # we use the indirect reference to get the value
      # for a specified key of an associative array
      refvar="$source[$1]"
      options[$(($arguments_count - $#))]=${!refvar:-$1}
      # parse next argument
      shift
    done
    # reset the positional parameters
    set -- "${options[@]}" '-- RETURN --'
  }

  echo_bold "$prompt"
  select option
  do
    if [[ -z $option ]]
    then
      die "ERROR: Invalid selection -- ABORTING!"
    fi
    if [[ $option == '-- RETURN --' ]]
    then
      echo
      return 1
    fi
    break
  done
  echo

  pos=''

  eval "pos=\$(expr \${REPLY} - 1) || true"

  eval "$result=\${arguments[$pos]}"

# there is a bug if the aurement is a number

#  eval "$result=\${arguments[\$(expr \${REPLY} - 1)]}"

  return 0
}

# Function: interactive_confirm
#
#    Wrapper function to construct a confirmation
#
# Arguments:
#
#    $1: prompt message shown at the begining
#    $2: exit on rejection? Optional.
#
interactive_confirm() {
  local confirm
  local prompt=$1 && shift
  declare -i rejdie=$1 && shift

  echo_bold "$prompt"
  echo -n "(YES to continue) "
  read confirm
  echo

  if [[ $(echo "$confirm" | tr '[:lower:]' '[:upper:]') != YES ]]
  then
    [[ $rejdie -eq 1 ]] && die "ERROR: Confirmation failed -- ABORTING!"
    return 1
  else
    return 0
  fi
}

# Function: interactive_readvar
#
#    Wrapper function to read value to a variable
#
# Arguments:
#
#    $1: variable name where to assign the result
#    $2: prompt information shown at the begining
#
interactive_readvar() {
  local result=$1 && shift
  local prompt=$1 && shift
  echo_bold "$prompt"
  local var
  read var
  echo
  eval "$result=\$var"
}

#
# Colorization
#

nrmred='\e[0;31m'          # normal red
nrmgrn='\e[0;32m'          # normal green
nrmylw='\e[0;33m'          # normal yellow
nrmblu='\e[0;34m'          # normal blue
nrmpur='\e[0;35m'          # normal purple
nrmcyn='\e[0;36m'          # normal cyan
nrmwht='\e[0;37m'          # normal white
bldred='\e[1;31m'          # blod red
bldgrn='\e[1;32m'          # blod green
bldylw='\e[1;33m'          # blod yellow
bldblu='\e[1;34m'          # blod blue
bldpur='\e[1;35m'          # blod purple
bldcyn='\e[1;36m'          # blod cyan
bldwht='\e[1;37m'          # blod white
txtbld=$(tput bold)        # bold
txtund=$(tput sgr 0 1)     # underline
txtrst='\e[0m'             # reset text


echo_bold() {
  echo -e ${txtbld}$@${txtrst}
}

echo_error() {
  echo -e ${bldred}$@${txtrst}
}

###############################################################################
#
# Git Wrappers
#
###############################################################################

_git_is_ref_valid() {
    local ref=${1:-ref not set}
    git show-ref --verify --quiet $ref || [[ $(git cat-file -t $ref) == commit ]]
}

_git_has_local_change() {
    ! git diff-index --quiet --exit-code HEAD
}

_git_is_head_detached() {
    ! git symbolic-ref HEAD &>/dev/null
}

_git_is_ref_in_remote() {
    local ref=${1:?ref not set}
    [[ -n "$(git branch -r --contains $ref)" ]]
}

_git_is_head_in_remote() {
    _git_is_ref_in_remote HEAD
}

_git_is_head_tracking_remote() {
    git rev-parse --abbrev-ref @{u} &>/dev/null
}

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
    "^__CATE"
    "^.git$"
    ".swp$"
)

debug() {
    local indent
    if [[ $DEPTH -gt 1 ]]
    then
        indent=$(printf '\t%.0s' $(seq 1 $(($DEPTH -1))))
    fi
    [[ $OPT_VERBOSE -eq 1 ]] && {
        echo -n $indent
        print $@
    }
}

print() {
    [[ -n "$2" ]] && echo -e $2
    [[ -n "$1" ]] && echo "$1"
    [[ -n "$2" ]] && echo -e $txtrst
}

printn() (
    [[ $OPT_VERBOSE -eq 1 ]] && {
        [[ -n "$1" ]] && print "$1"
    } || {
        [[ -n "$1" ]] && echo -e "$1"
    }
)

printh() (
    [[ $OPT_VERBOSE -eq 1 ]] && {
        [[ -n "$1" ]] && print "\e[1;37m$1\e[0m"
    } || {
        [[ -n "$1" ]] && echo -e "\e[1;37m$1\e[0m"
    }
)

printe() (
    exec 1>&2
    [[ $OPT_VERBOSE -eq 1 ]] && {
        [[ -n "$1" ]] && print "ERROR: $1"
    } || {
        [[ -n "$1" ]] && echo -e "ERROR: $1"
    }
)

printw() (
    exec 1>&2
    [[ $OPT_VERBOSE -eq 1 ]] && {
        [[ -n "$1" ]] && print "Warning: $1"
    } || {
        [[ -n "$1" ]] && echo -e "Warning: $1"
    }
)

# Abtain the record to the source
get_src() {
    if [[ $1 =~ .*\.__SRC ]]
    then
        head -1 $1
    else
        echo $1
    fi
}

# Directory to store the VCS source
get_dir() {
    mkdir -p $CONFDIR/vcs/ &>/dev/null

    echo $CONFDIR/vcs/$(echo "$1" | md5sum - | cut -d ' ' -f 1)
}

# extract the URL from a source entry
get_url() {
    # strip an eventual filename
    printf "%s\n" "${1#*::}"
}

# extract the protocol from a source entry - return "local" for local sources
get_protocol() {
    if [[ $1 = *://* ]]
    then
        # strip leading filename
        local proto="${1##*::}"
        printf "%s\n" "${proto%%://*}"
    else
        printf "%s\n" local
    fi
}

# extract the filename from a source entry
get_filename() {
    local src=$1

    # if a filename is specified, use it
    if [[ $src = *::* ]]
    then
        printf "%s\n" ${src%%::*}
        return
    fi

    local proto=$(get_protocol "$src")
    case $proto in
        git*)
            filename=${src%%#*}
            filename=${filename%/}
            filename=${filename##*/}
            if [[ $proto = git* ]]
            then
                filename=${filename%%.git*}
            fi
            ;;
        *)
            # if it is just an URL, we only keep the last component
            filename="${src##*/}"
            ;;
    esac
    printf "%s\n" "${filename}"
}

# Return the absolute filename of a source entry
get_filepath() {
    local src=$(get_src "$1")

    local file=$(get_fragment "$src"  "file")
    local proto=$(get_protocol "$src")
    case "$proto" in
        git*)
            if [[ -n $file ]]
            then
                echo $(get_dir $src)/$file
            else
                echo $(get_dir $src)
            fi
            ;;
        local)
            echo $(get_url "$src")
            ;;
    esac
}

get_fragment() {
    local url=$1
    local target=$2
    local fragment=${url#*#}

    if [[ $fragment = "$url" ]]
    then
        return
    fi

    if [[ -n $fragment ]]
    then
        if [[ $target = ref ]]
        then
            if [[ $fragment =~ tag=* ]]
            then
                echo $fragment | sed 's/.*tag=\([^&]*\).*/\1/g;s|^refs/tags/||;s|^|refs/tags/|'
            elif [[ $fragment =~ branch=* ]]
            then
                echo $fragment | sed 's/.*branch=\([^&]*\).*/\1/g;s|^refs/heads/||;s|^refs/remotes/origin/||;s|^|refs/remotes/origin/|'
            elif [[ $fragment =~ commit=* ]]
            then
                echo $fragment | sed 's/.*commit=\([^&]*\).*/\1/g'
            fi
        elif [[ $target = file ]]
        then
            if [[ $fragment =~ file=* ]]
            then
                echo $fragment | sed 's/.*file=\([^&]*\).*/\1/g'
            fi
        fi
    fi
}

ensure_source() {
    local src=$1

    declare -a ensured

    if [[ " ${arr[*]} " == *" $src "* ]]; then
        return
    fi

    ensured+=("$src")

    local proto=$(get_protocol "$src")
    case "$proto" in
        git*)
            ensure_source_git "$src"
            ;;
        local)
            ensure_source_local "$src"
            ;;
        *)
            printe "Unkown protocol $proto ..."
            exit 1
            ;;
    esac

    get_filepath $src
}

ensure_source_git() (
set -e
    local src=$1
    local dir=$(get_dir "$src")

    mkdir -p $CONFDIR/vcs/

    local url=$(get_url "$src")
    url=${url##*git+}
    url=${url##*ssh:\/\/}
    url=${url##*file:\/\/}
    url=${url%%#*}

    # Fetch the remote update if we have it cloned already and the upstream is correct
    if [[ -d "$dir/.git" ]] && ( _cd "$dir" && [[ "$url" == "$(git config --get remote.origin.url)" ]] )
    then
        if ( _cd "$dir" && ! git fetch --all --prune --quiet )
        then
            printw "Failed to fetch upstream '$url' in '$dir'."
        else
            ( _cd "$dir" && git remote set-head origin -a &>/dev/null )
        fi
    # Otherwise, backup and remove any existed invalid file/directory occupied the target
    # location before the clone
    else
        if [[ -e "$dir" ]] && { [[ ! -d "$dir" ]] || { [[ -d "$dir" ]] && ! _is_dir_empty "$dir"; }; }
        then
            DEPTH=$(( $DEPTH + 1 ))
            printh 'BACKUP:'$'\t'"$dir"
            DEPTH=$(( $DEPTH + 1 ))
            local bakdir=$BAKPATH/$(dirname "${dir##$DESTHOME/}")
            _mkdir "$bakdir"
            printn "$(mv -v $dir $bakdir)"
            DEPTH=$(( $DEPTH - 1 ))
            DEPTH=$(( $DEPTH - 1 ))
        fi

        _mkdir $CONFDIR/vcs/

        if ! git clone --quiet "$url" "$dir"
        then
            printe "Failed to clone repository '$url' to '$dir'."
            exit 1
        fi
    fi

    _cd "$dir"

    if _git_has_local_change || { _git_is_head_detached && ! _git_is_head_in_remote; } || { _git_is_head_tracking_remote && ! _git_is_head_in_remote; }
    then
        printw "Our clone of the repository $(pwd) has local changes, abort further operation, please resolve first."
        exec 1>&2
        git diff
        exec 1>&1
    fi

    local ref=$(get_fragment "$src"  "ref")
    if [[ -z $ref ]] || { ! _git_is_ref_valid $ref && printw "$ref is not a valid git ref, use HEAD of origin."; }
    then
        #keep the head in sync with the remote
        ref=refs/remotes/origin/HEAD
    fi

    if [[ $(git rev-parse HEAD) != $(git rev-parse $ref) ]]
    then
        if _git_has_local_change || { _git_is_head_detached && ! _git_is_head_in_remote; } || { _git_is_head_tracking_remote && ! _git_is_head_in_remote; }
        then
            :
        else
            if [[ $ref =~ ^refs/remotes/origin ]] && [[ $ref != refs/remotes/origin/HEAD ]]
            then
                if ! { git checkout --quiet ${ref##refs/remotes/origin/} && git reset --hard --quiet $ref; }
                then
                    printw "Unable to keep the branch in sync with upstream"
                fi
            else
                if ! git checkout --quiet $ref
                then
                    if [[ $ref == "refs/remotes/origin/HEAD" ]]
                    then
                        printw "Unable to keep HEAD in sync with remote"
                    else
                        printw "Unable to checkout requested reference"
                    fi
                fi
            fi
        fi
    fi

    if [[ $OPT_VCS_CLEAN == 1 ]]
    then
        # clean dangling objects
        git reflog expire --expire=now --all

        # clean safe-keeping references
        refbak=$(git for-each-ref --format="%(refname)" refs/original/)
        if [ -n "$refbak" ]
        then
            echo -n $refbak | xargs -n 1 git update-ref -d
        fi

        # show git database status
        git fsck

        # repack git database objects
        git repack -a -d

        # collect garbage
        git gc --prune=now --aggresive
    fi
set +e
)

ensure_source_local() (
    # TODO check for existance
    true
)

_diff() {
    echo "diff -y --color=always $1 $2"
    printf '=%.0s' $(seq 1 $((120 -1)))
    echo
    diff -y --color=always $1 $2
    printf '=%.0s' $(seq 1 $((120 -1)))
    echo
}

_mkdir() {
    local dir=$1

    if [[ ! -d $dir ]]
    then
        print $'MKDIR:\t'"$dir"
        mkdir -p "$dir"
    fi

    if [[ ! -d $dir ]]
    then
        printe "Failed to create directory $dir"
        exit 1
    fi
}

#
# Function: _prune
#
# Remove broken symlinks
#
# Parameters:
#   $1  log file recorded the deployed symlinks
#
_prune() {
    local logfile=$1

    sort -u $logfile -o $logfile

    local file
    for file in $(cat $logfile); do
        [[ ! -h $file ]] && {
            sed -i "/^${file//\//\\\/}$/d" $logfile
        }

        _check $file

        [[ $? -eq 5 ]] && {
            DEPTH=$(( $DEPTH + 1 ))
            DEPTH=$(( $DEPTH + 1 ))
            [[ $status -eq 0 ]] && need_prune+=("$file")
            if [[ $OPT_DRY_RUN != 1 ]]
            then
                print "$(rm -v $file)"
            fi
            DEPTH=$(( $DEPTH - 1 ))
            DEPTH=$(( $DEPTH - 1 ))
        }
    done
}

#
# Function: _check
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
#   5 can not found src
#
_check() {
    local src
    local dst=$1
    local repath

    repath=${dst#$DESTHOME}
    repath=${repath#/}

    [[ -e $DOTSREPO/$repath ]] && src=$DOTSREPO/$repath
    [[ -e $DOTSREPO/$repath.__SRC ]] && src=$DOTSREPO/$repath.__SRC
    for cate in "${OPT_CATE[@]}"
    do
        [[ -e $DOTSREPO/__CATE.$cate/$repath ]] && src=$DOTSREPO/__CATE.$cate/$repath
        [[ -e $DOTSREPO/__CATE.$cate/$repath.__SRC ]] && src=$DOTSREPO/__CATE.$cate/$repath.__SRC
    done
    [[ -e $DOTSREPO/__HOST.$HOST/$repath ]] && src=$DOTSREPO/__HOST.$HOST/$repath
    [[ -e $DOTSREPO/__HOST.$HOST/$repath.__SRC ]] && src=$DOTSREPO/__HOST.$HOST/$repath.__SRC
    for cate in "${OPT_CATE[@]}"
    do
        [[ -e $DOTSREPO/__HOST.$HOST/__CATE.$cate/$repath ]] && src=$DOTSREPO/__HOST.$HOST/__CATE.$cate/$repath
        [[ -e $DOTSREPO/__HOST.$HOST/__CATE.$cate/$repath.__SRC ]] && src=$DOTSREPO/__HOST.$HOST/__CATE.$cate/$repath.__SRC
    done
    [[ -e $DOTSREPO/__USER.$USER/$repath ]] && src=$DOTSREPO/__USER.$USER/$repath
    [[ -e $DOTSREPO/__USER.$USER/$repath.__SRC ]] && src=$DOTSREPO/__USER.$USER/$repath.__SRC
    for cate in "${OPT_CATE[@]}"
    do
        [[ -e $DOTSREPO/__USER.$USER/__CATE.$cate/$repath ]] && src=$DOTSREPO/__USER.$USER/__CATE.$cate/$repath
        [[ -e $DOTSREPO/__USER.$USER/__CATE.$cate/$repath.__SRC ]] && src=$DOTSREPO/__USER.$USER/__CATE.$cate/$repath.__SRC
    done
    [[ -e $DOTSREPO/__HOST.$HOST/__USER.$USER/$repath ]] && src=$DOTSREPO/__HOST.$HOST/__USER.$USER/$repath
    [[ -e $DOTSREPO/__HOST.$HOST/__USER.$USER/$repath.__SRC ]] && src=$DOTSREPO/__HOST.$HOST/__USER.$USER/$repath.__SRC
    for cate in "${OPT_CATE[@]}"
    do
        [[ -e $DOTSREPO/__HOST.$HOST/__USER.$USER/__CATE.$cate/$repath ]] && src=$DOTSREPO/__HOST.$HOST/__USER.$USER/__CATE.$cate/$repath
        [[ -e $DOTSREPO/__HOST.$HOST/__USER.$USER/__CATE.$cate/$repath.__SRC ]] && src=$DOTSREPO/__HOST.$HOST/__USER.$USER/__CATE.$cate/$repath.__SRC
    done

    # can not find the source
    [[ -z $src ]] && {
        return 5
    }

    src=$(realpath $src 2>/dev/null || echo $src)

    if [[ -h $dst ]]
    then
        local csrc=$(readlink $dst)
        csrc=$(realpath $csrc 2>/dev/null || echo $csrc)

        if [[ "$csrc" == "$src" ]]
        then
            return 0
        elif [[ $src =~ .*\.__SRC ]]
        then
            src=$(get_filepath "$src")
            src=$(realpath $src 2>/dev/null || echo $src)
            if [[ $csrc == $src ]]
            then
              return 0
            else
              echo csrc $csrc
              echo aaa $src
              return 2
            fi
        else
            if [[ $csrc =~ $DOTSHOME ]]
            then
                return 1
            else
                return 2
            fi
        fi
    elif [[ -d $dst ]]
    then
        if [[ -f $src/__KEEPED ]]
        then
            return 4
        else
            return 2
        fi
    elif [[ -f $dst ]]
    then
        return 2
    else
        return 3
    fi
}

#
# Function: _deploy
#
# Deploy files
#
# Parameters:
#   $1  directory containing dot files
#   $2  directory where files need to go
#
# This function can be called recursively.
#
_deploy() {
    local dotdir=$1
    local dstdir=$2

    DEPTH=$(( $DEPTH + 1 ))
    debug 'ENTER:'$'\t'"$dotdir"

    local filelist=$(ls -1A --color=none $dotdir)

    local file
    for file in $filelist; do
        # skip preserved filenames
        local line
        for line in ${IGNORE[@]};do
            [[ $file =~ $line ]] && continue 2
        done

        # apply user-defined ignoring rules
        if [[ -f $dotdir/__IGNORE ]]
        then
            local line
            for line in $(cat $dotdir/__IGNORE);do
                [[ $file =~ $line ]] && continue 2
            done
        fi

        if [[ -d $dotdir/$file ]]
        then
            if [[ -e $dotdir/$file/__KEEPED ]]
            then
                # this directory needs to be kept,
                # deploy its contents.
                _deploy $dotdir/$file $dstdir/$file
            else
                plan[$dstdir/${file%%.__SRC}]=$dotdir/$file
            fi
        elif [[ -f $dotdir/$file ]]
        then
            plan[$dstdir/${file%%.__SRC}]=$dotdir/$file
        fi
    done

    debug 'LEAVE:'$'\t'"$dotdir"
    DEPTH=$(( $DEPTH - 1 ))
}

#
# Function: _symlink
#
# Make a symlink.
#
# If the target file exists, backup it first.
#
# Parameters:
#   $1  source directory where the dotfile is located
#   $2  target directory where the dotfile will be deployed
#
_symlink() {
    local src=$1
    local dst=$2

    [[ $src =~ ^.*.__SRC$ ]] && {
        ensure_source "$(get_src "$1")" || return
        src=$(get_filepath "$1")
        dst=${2}
    }

    local repath

    repath=$dst
    repath=$(echo $repath | sed 's/[^/]\+$//')

    # for nested path, need to mkdir parent first
    [[ -n "$repath" ]] && {
        # backup if the target already exits
        [[ -f "$DESTHOME/$repath" ]] && {
            DEPTH=$(( $DEPTH + 1 ))
            printh 'BACKUP:'$'\t'"$DESTHOME/$repath"
            DEPTH=$(( $DEPTH + 1 ))
            if [[ $OPT_DRY_RUN != 1 ]]
            then
                print "$(_mkdir $BAKPATH/${repath#$DESTHOME} && mv -v $repath $BAKPATH/${repath#$DESTHOME})"
            fi
            DEPTH=$(( $DEPTH - 1 ))
            DEPTH=$(( $DEPTH - 1 ))
        }
        DEPTH=$(( $DEPTH + 1 ))
        if [[ $OPT_DRY_RUN != 1 ]]
        then
            print "$(_mkdir $repath)"
        fi
        DEPTH=$(( $DEPTH - 1 ))
    }

    _check $dst

    local status=$?

    # remove broken link
    [[ $status -eq 1 ]] && {
        DEPTH=$(( $DEPTH + 1 ))
        debug 'REMOVE:'$'\t'"$dst"
        DEPTH=$(( $DEPTH + 1 ))
        if [[ $OPT_DRY_RUN != 1 ]]
        then
            print "$(rm -v $dst)"
        fi
        DEPTH=$(( $DEPTH - 1 ))
        DEPTH=$(( $DEPTH - 1 ))
    }

    # backup existed file
    [[ $status -eq 2 ]] && {
        [[ $OPT_FORCE = 1 ]] && {
            DEPTH=$(( $DEPTH + 1 ))
            debug 'BACKUP:'$'\t'"$dst"
            DEPTH=$(( $DEPTH + 1 ))
            if [[ $OPT_DRY_RUN != 1 ]]
            then
                print "$(_mkdir $BAKPATH/${repath#$DESTHOME} && mv -v $dst $BAKPATH/${repath#$DESTHOME})"
            fi
            DEPTH=$(( $DEPTH - 1 ))
            DEPTH=$(( $DEPTH - 1 ))
        } || {
            printw "$dst already exists, use --force option to force deploying"
            return
        }
    }

    # symlink the file in the repo
    [[ $status -ne 0 ]] && [[ $status -ne 4 ]] && {
        DEPTH=$(( $DEPTH + 1 ))
        debug 'LINK:'$'\t'"$dst"
        DEPTH=$(( $DEPTH + 1 ))
        if [[ $OPT_DRY_RUN != 1 ]]
        then
            print "$(ln -v -s $src $dst)"
        fi
        DEPTH=$(( $DEPTH - 1 ))
        DEPTH=$(( $DEPTH - 1 ))

        grep "^$dst\$" $LOGFILE >/dev/null 2>&1

        [[ $? -ne 0 ]] && echo "$dst" >> $LOGFILE
    }
}

doadd() {
    #check if our target is in the desthome
    [[ $TARGET =~ $DESTHOME/.* ]] || die "target not in dest home"

    local rpath=${TARGET##$DESTHOME/}

    local dest
    if [[ $OPT_HOST == 0 ]] && [[ $OPT_USER == 0 ]]
    then
        dest=$DOTSREPO
    elif [[ $OPT_HOST == 1 ]] && [[ $OPT_USER == 0 ]]
    then
        dest=$DOTSREPO/__HOST.$HOST
    elif [[ $OPT_HOST == 0 ]] && [[ $OPT_USER == 1 ]]
    then
        dest=$DOTSREPO/__USER.$USER
    elif [[ $OPT_HOST == 1 ]] && [[ $OPT_USER == 1 ]]
    then
        dest=$DOTSREPO/__HOST.$HOST/__USER.$USER
    fi

    #check if the target already in the destination
    [[ -e $dest/$rpath ]] && [[ $OPT_FORCE == 0 ]] && {
        die "target already exists"
    }

    local file=$(basename $rpath)

    #move the target to the destination
    _mkdir "$dest/${rpath%%$file}"
    mv "$TARGET" "$dest/${rpath%%$file}"

    [[ $rpath == $file ]] || {
        touch "$dest/${rpath%%$file}/__KEEPED"
    }

    #link the target back
    _symlink "$dest/${rpath%%$file}" "${TARGET%%$file}" $file
}

doremove() {
    #check if our target is a real link
    [[ -h $TARGET ]] || die "target is not a link"

    #check if our target is in the desthome
    [[ $TARGET =~ $DESTHOME/.* ]] || die "target not in dest home"

    #check if our target is linking to our dots repo
    [[ $(readlink -fm $TARGET) =~ $DOTSREPO/.* ]] || die "target not link to our repo"

    local src=$(readlink -fm $TARGET)

    #remove the link
    rm -v $TARGET

    [[ $OPT_FORCE == 0 ]] && {
        #copy the original file
        cp -v -rf $src $(dirname $TARGET)
    } || {
        #remove the original file
        rm -v -rf $src
    }
}

dodeploy() {
    # backup location, categarized by date
    BAKPATH=$CONFDIR/backup/`date +%Y%m%d.%H.%M.%S`

    # transform old backup sctruction to the new one
    [[ -d $DOTSHOME/__BACKUP/$HOST ]] && {
        echo "Performing transition ..."

        [[ -f $LOGFILE ]] && mv $LOGFILE $LOGFILE.bak
        for bakpath in $(grep -l "^$DESTHOME\$" $DOTSHOME/__BACKUP/$HOST/*/DESTHOME | sed 's-/DESTHOME$--g');do
            mv $bakpath/dotploy.log $LOGFILE &>/dev/null

            [[ -f $bakpath/dotploy.log ]] && {
                echo error
                continue
            }

            rm $bakpath/DESTHOME &>/dev/null

            [[ -f $bakpath/DESTHOME ]] && {
                echo error
                continue
            }

            rmdir $bakpath &> /dev/null || mv $bakpath $CONFDIR/backup
        done
        [[ -f $LOGFILE.bak ]] && mv $LOGFILE.bak $LOGFILE

        rmdir --ignore-fail-on-non-empty -p $DOTSHOME/__BACKUP/$HOST

        echo "Transition done."
    }

declare -a need_prune

    if [[ -f $LOGFILE ]]
    then
        _prune $LOGFILE
    fi

declare -A plan

    # shared dotfiles deploy
    _deploy $DOTSREPO $DESTHOME

    for cate in "${OPT_CATE[@]}"
    do
        if [[ -d $DOTSREPO/__CATE.$cate ]]
        then
            _deploy $DOTSREPO/__CATE.$cate $DESTHOME
        fi
    done

    # host based dotfies deploy
    if [[ -d $DOTSREPO/__HOST.$HOST ]]
    then
        _deploy $DOTSREPO/__HOST.$HOST $DESTHOME

        for cate in "${OPT_CATE[@]}"
        do
            if [[ -d $DOTSREPO/__HOST.$HOST/__CATE.$cate ]]
            then
                _deploy $DOTSREPO/__HOST.$HOST/__CATE.$cate $DESTHOME
            fi
        done
    fi

    # user based dotfies deploy
    if [[ -d $DOTSREPO/__USER.$USER ]]
    then
        _deploy $DOTSREPO/__USER.$USER $DESTHOME

        for cate in "${OPT_CATE[@]}"
        do
            if [[ -d $DOTSREPO/__USER.$USER/__CATE.$cate ]]
            then
                _deploy $DOTSREPO/__USER.$USER/__CATE.$cate $DESTHOME
            fi
        done
    fi

    # host user based dotfies deploy
    if [[ -d $DOTSREPO/__HOST.$HOST/__USER.$USER ]]
    then
        _deploy $DOTSREPO/__HOST.$HOST/__USER.$USER $DESTHOME

        for cate in "${OPT_CATE[@]}"
        do
            if [[ -d $DOTSREPO/__HOST.$HOST/__USER.$USER/__CATE.$cate ]]
            then
                _deploy $DOTSREPO/__HOST.$HOST/__USER.$USER/__CATE.$cate $DESTHOME
            fi
        done
    fi

declare -a all_good
declare -a need_update
declare -a need_backup
declare -a need_link
declare -a deploy_contents
declare -a remove

for K in "${!plan[@]}"
do
#    echo $K
#    echo ${plan[$K]}

    [[ ${plan[$K]} =~ ^.*.__SRC$ ]] && {
        print "Update all git source"
        ensure_source "$(get_src "${plan[$K]}")" || return
    }

    _check $K

    local status=$?

    # remove broken link
    [[ $status -eq 0 ]] && all_good+=("$K")
    [[ $status -eq 1 ]] && need_update+=("$K")
    [[ $status -eq 2 ]] && need_backup+=("$K")
    [[ $status -eq 3 ]] && need_link+=("$K")
    [[ $status -eq 4 ]] && deploy_contents+=("$K")
    [[ $status -eq 5 ]] && remove+=("$K")
done

print ">>>>>>> ALL GOOD" $bldblu
for i in "${all_good[@]}"
do
    print $i $txtbld
done

print ">>>>>>> NEED UPDATE" $bldblu
for i in "${need_update[@]}"
do
    print $i $txtbld

    local csrc=$(readlink $i)
    echo CURRENT: $csrc
    echo should be: ${plan[$i]}
    csrc=$(realpath $csrc 2>/dev/null || echo $csrc)
    _diff $csrc ${plan[$i]}
    if interactive_confirm "Proceed?"
    then
        echo ${plan[$i]}
        echo $i
        _symlink ${plan[$i]} $i
    fi
done

print ">>>>>>> NEED BACKUP" $bldblu
for i in "${need_backup[@]}"
do
    print $i $txtbld

    dst=$i
    src=${plan[$i]}
    if [[ $src =~ .*\.__SRC ]]
    then
        src=$(get_filepath "$src")
    fi

    if [[ -h $dst ]]
    then
        echo CURRENT: $(readlink $dst)
        echo should be: $src
    elif [[ -f $dst ]]
    then
        echo "dst: $(md5sum $dst)"
        echo "src: $(md5sum $src)"

        _diff $dst $src

        # todo if md5sum is the same, no need to backup
    else
        echo CURRENT: $dst
        echo should be: $src
    fi

    if interactive_confirm "Proceed?"
    then
        echo ${plan[$i]}
        echo $i
        _symlink ${plan[$i]} $i
    fi
done

print ">>>>>>> NEED LINK" $bldblu
for i in "${need_link[@]}"
do
    print $i $txtbld
    echo LINK TO: ${plan[$i]}

    if interactive_confirm "Proceed?"
    then
        echo ${plan[$i]}
        echo $i
        _symlink ${plan[$i]} $i
    fi
done

print ">>>>>>> NEED CONTENT" $bldblu
for i in "${deploy_contents[@]}"
do
    print $i $txtbld

    if interactive_confirm "Proceed?"
    then
        echo ${plan[$i]}
        echo $i
        _symlink ${plan[$i]} $i
    fi
done

print ">>>>>>> NEED REMOVE" $bldblu
for i in "${remove[@]}"
do
    print $i $txtbld

    if interactive_confirm "Proceed?"
    then
        echo ${plan[$i]}
        echo $i
        _symlink ${plan[$i]} $i
    fi
done
for i in "${need_prune[@]}"
do
    print $i $txtbld

    if interactive_confirm "Proceed?"
    then
        echo ${plan[$i]}
        echo $i
        _symlink ${plan[$i]} $i
    fi
done
}

show_help() {
    cat << 'EOF'

Usage:

    dotploy.sh add [--user] [--host] [--force] <file> <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

        add <file> to the dots repo, and link it back

    dotploy.sh remove <file> <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

        Remove the link of <file> to the dots repo, and copy the original file back

    dotploy.sh deploy [--force] <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

        deploy the dots repo the the destination

Options:

    -h, show help information
    -v, be verbose about the process
    --user,
        add to the `__USER.$USER` directory
    --host,
        add to the `__HOST.$HOST` directory
    --user --host,
        add to the `__HOST.$HOST/__USER.$USER` directory
    --force,
        for 'add' action, if the file exists in dots repo, enabling this
        option will overwrite it;
        for 'deploy' action, if the file exists in deployment destination,
        enabling this option will backup the existing file first.

The argument `<destination_of_the_deployment>` is optional. If it is absent,
then current `$HOME` directory will be used.

Conflicted files will be backed up into `.dotploy/` directory under your
deployment destination.

EOF
}

declare -a args
declare -i DEPTH=0
declare -i OPT_USER=0
declare -i OPT_HOST=0
declare -a OPT_CATE
declare -i OPT_FORCE=0
declare -i OPT_VERBOSE=0
declare -i OPT_DRY_RUN=0
declare -i OPT_VCS_CLEAN=0
while [[ $# -gt 0 ]]
do
    case "$1" in
        --user )
            OPT_USER=1
        ;;
        --host )
            OPT_HOST=1
        ;;
        --cate )
            OPT_CATE+=("$2")
            shift
        ;;
        --force )
            OPT_FORCE=1
        ;;
        --debug )
            set -xv
        ;;
        --dry-run )
            OPT_DRY_RUN=1
        ;;
        --vcs-clean )
            OPT_VCS_CLEAN=1
        ;;
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
            OPT_VERBOSE=1
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

ACTION=$1
case "$ACTION" in
    add | remove )
        shift
        TARGET=$(realpath --no-symlinks ${1%%\/})
        shift
        ;;
    deploy )
        shift
        ;;
    * )
        show_help
        exit 1
        ;;
esac

DESTHOME=$(realpath ${2:-${DESTHOME:-$HOME}})

# make sure our destination is there
[[ -d $DESTHOME ]] || die "$DESTHOME is not available"

CONFDIR=$DESTHOME/.dotploy

_mkdir $CONFDIR

[[ -f "$CONFDIR/config" ]] && source $CONFDIR/config

# keep a record of the deployed files
LOGFILE=$CONFDIR/filelog

DOTSHOME=$(ensure_source $1)

# make sure our destination is there
[[ -d $DOTSHOME ]] || die "$DOTSHOME is not available"

DOTSREPO=$(realpath $DOTSHOME/__DOTDIR)

# die if it is not a dotsrepo
[[ -d $DOTSREPO ]] || die "$DOTSREPO is not available"

do$ACTION
