#!/bin/bash

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

_basedir() {
    if [[ $1 =~ .*\/$ ]]; then
        echo $1
    else
        dirname $1
    fi
}

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
