#!/bin/bash

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

if [[ -f $ABSPATH/../../../libs/bashTest/src/bashTest ]]
then
    source "$ABSPATH/../../../libs/bashTest/src/bashTest"
elif [[ -f $ABSPATH/../bundles/bashTest/src/bashTest ]]
then
    source "$ABSPATH/../bundles/bashTest/src/bashTest"
elif [[ -f /usr/share/dotploy/bundles/bashTest/bashTest ]]
then
    source "/usr/share/dotploy/bundles/bashTest/bashTest"
elif [[ -f /usr/share/lib/bashTest/bashTest ]]
then
    source "/usr/share/lib/bashTest/bashTest"
else
    echo "Can not find bashTest, you need to install it as bundles first."
    exit 1
fi

ABSPATH=$(_abspath)

USER=$(id -nu)
HOST=$HOSTNAME

__test_layer=(
    "__BACKUP/"
    "__DOTDIR/.dotdir1/__KEEPED"
    "__DOTDIR/.dotdir1/subdir/subdirfile"
    "__DOTDIR/.dotdir1/subfile"
    "__DOTDIR/.dotdir2/__KEEPED"
    "__DOTDIR/.dotdir2/subdir/subdirfile"
    "__DOTDIR/.dotdir2/subfile"
    "__DOTDIR/.dotdir3/subdir/subdirfile"
    "__DOTDIR/.dotdir3/subfile"
    "__DOTDIR/.dotdir4/subdir/subdirfile"
    "__DOTDIR/.dotdir4/subfile"
    "__DOTDIR/.dotfile1"
    "__DOTDIR/.dotfile2"
    "__DOTDIR/.dotfile3"
    "__DOTDIR/.dotfile4"
    "__DOTDIR/.dotfile5"
    "__DOTDIR/.dotfile6"
    "__DOTDIR/__HOST.$HOST/.dotdir1/__KEEPED"
    "__DOTDIR/__HOST.$HOST/.dotdir1/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/.dotdir1/subfile"
    "__DOTDIR/__HOST.$HOST/.dotdir2/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/.dotdir2/subfile"
    "__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
    "__DOTDIR/__HOST.$HOST/.dotdir3/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    "__DOTDIR/__HOST.$HOST/.dotdir5/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/.dotdir5/subfile"
    "__DOTDIR/__HOST.$HOST/.dotfile3"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir1/__KEEPED"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir1/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir1/subfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir2/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir2/subfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir3/__KEEPED"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir3/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir3/subfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir5/subdir/subdirfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir5/subfile"
    "__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
    "__DOTDIR/__USER.$USER/.dotdir1/__KEEPED"
    "__DOTDIR/__USER.$USER/.dotdir1/subdir/subdirfile"
    "__DOTDIR/__USER.$USER/.dotdir1/subfile"
    "__DOTDIR/__USER.$USER/.dotdir2/subdir/subdirfile"
    "__DOTDIR/__USER.$USER/.dotdir2/subfile"
    "__DOTDIR/__USER.$USER/.dotdir3/__KEEPED"
    "__DOTDIR/__USER.$USER/.dotdir3/subdir/subdirfile"
    "__DOTDIR/__USER.$USER/.dotdir3/subfile"
    "__DOTDIR/__USER.$USER/.dotdir5/subdir/subdirfile"
    "__DOTDIR/__USER.$USER/.dotdir5/subfile"
    "__DOTDIR/__USER.$USER/.dotfile2"
    "__UNUSED/"
)

__test_field=$ABSPATH'/test-field'

__test_dotsdest=$__test_field'/dotsdest'
__test_dotsrepo=$__test_field'/dotsrepo'

_set_up() {
    mkdir -p $__test_dotsdest
    mkdir -p $__test_dotsrepo
    for layer in ${__test_layer[@]};do
        mkdir -p $__test_dotsrepo'/'$(_basedir $layer) && touch $__test_dotsrepo'/'$layer
    done
}

_tear_down() {
    rm -r $__test_dotsdest
    rm -r $__test_dotsrepo
}

_set_up
$(dirname $0)/../dotploy.sh $__test_dotsrepo $__test_dotsdest
_tear_down
