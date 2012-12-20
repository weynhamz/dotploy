#!/bin/bash

[ -f ../../tests/bootstrap.sh ] && . ../../tests/bootstrap.sh

USER='techlive'
HOSTNAME='home'

__test_layer=(
    '__BACKUP/'
    '__DOTDIR/.dotdir1/__KEEPED'
    '__DOTDIR/.dotdir1/subdir/subdirfile'
    '__DOTDIR/.dotdir1/subfile'
    '__DOTDIR/.dotdir2/__KEEPED'
    '__DOTDIR/.dotdir2/subdir/subdirfile'
    '__DOTDIR/.dotdir2/subfile'
    '__DOTDIR/.dotdir3/subdir/subdirfile'
    '__DOTDIR/.dotdir3/subfile'
    '__DOTDIR/.dotdir4/subdir/subdirfile'
    '__DOTDIR/.dotdir4/subfile'
    '__DOTDIR/.dotfile1'
    '__DOTDIR/.dotfile2'
    '__DOTDIR/.dotfile3'
    '__DOTDIR/.dotfile4'
    '__DOTDIR/.dotfile5'
    '__DOTDIR/.dotfile6'
    '__DOTDIR/__HOST.home/.dotdir1/__KEEPED'
    '__DOTDIR/__HOST.home/.dotdir1/subdir/subdirfile'
    '__DOTDIR/__HOST.home/.dotdir1/subfile'
    '__DOTDIR/__HOST.home/.dotdir2/subdir/subdirfile'
    '__DOTDIR/__HOST.home/.dotdir2/subfile'
    '__DOTDIR/__HOST.home/.dotdir3/__KEEPED'
    '__DOTDIR/__HOST.home/.dotdir3/subdir/subdirfile'
    '__DOTDIR/__HOST.home/.dotdir3/subfile'
    '__DOTDIR/__HOST.home/.dotdir5/subdir/subdirfile'
    '__DOTDIR/__HOST.home/.dotdir5/subfile'
    '__DOTDIR/__HOST.home/.dotfile3'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir1/__KEEPED'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir1/subdir/subdirfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir1/subfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir2/subdir/subdirfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir2/subfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir3/__KEEPED'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir3/subdir/subdirfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir3/subfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir5/subdir/subdirfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotdir5/subfile'
    '__DOTDIR/__HOST.home/__USER.techlive/.dotfile4'
    '__DOTDIR/__USER.techlive/.dotdir1/__KEEPED'
    '__DOTDIR/__USER.techlive/.dotdir1/subdir/subdirfile'
    '__DOTDIR/__USER.techlive/.dotdir1/subfile'
    '__DOTDIR/__USER.techlive/.dotdir2/subdir/subdirfile'
    '__DOTDIR/__USER.techlive/.dotdir2/subfile'
    '__DOTDIR/__USER.techlive/.dotdir3/__KEEPED'
    '__DOTDIR/__USER.techlive/.dotdir3/subdir/subdirfile'
    '__DOTDIR/__USER.techlive/.dotdir3/subfile'
    '__DOTDIR/__USER.techlive/.dotdir5/subdir/subdirfile'
    '__DOTDIR/__USER.techlive/.dotdir5/subfile'
    '__DOTDIR/__USER.techlive/.dotfile2'
    '__UNUSED/'
)

if [ -n "$SHELL_TOOLKIT_TEST_FIELD" ]; then
    __test_field=$SHELL_TOOLKIT_TEST_FIELD'/dotploy'
else
    __test_field=$(dirname $0)'/test-field'
fi

__test_dotsdest=$__test_field'/dotsdest'
__test_dotsrepo=$__test_field'/dotsrepo'

_basedir() {
    if [[ $1 =~ .*\/$ ]]; then
        echo $1
    else
        dirname $1
    fi
}

_test_field() {
    mkdir -p $__test_dotsdest
    mkdir -p $__test_dotsrepo
    for layer in ${__test_layer[@]};do
        mkdir -p $__test_dotsrepo'/'$(_basedir $layer) && touch $layer
    done
}

_test_field

$(dirname $0)/../dotploy.sh -d $__test_dotsrepo $__test_dotsdest
$(dirname $0)/../dotploy.sh -r $__test_dotsrepo $__test_dotsdest
