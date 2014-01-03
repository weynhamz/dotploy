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

###############################################################################
#
# Test Helpers
#
###############################################################################

ABSPATH=$(_abspath)

_set_up() {
    export PATH=$(realpath $ABSPATH/..):$PATH

    export TEST_FIELD=$ABSPATH'/test-field/'$TEST_COUNT

    rm -rf "$TEST_FIELD" || die "Failed to set up test facility."

    mkdir -p "$TEST_FIELD/dotsdest"
    mkdir -p "$TEST_FIELD/dotsrepo"
    mkdir -p "$TEST_FIELD/dotsrepo/__DOTDIR"

    cd "$TEST_FIELD"
}

_tear_down() {
    true
}

_make_layer() {
    local layer
    for layer in "$@";do
        mkdir -p "$(_dirname "$layer")" && touch "$layer"
    done
}

###############################################################################
#
# Git Wrappers
#
###############################################################################

_git_tag() (
    exec &>/dev/null
    cd test.git

    git tag "$@"
)

_git_init() (
    exec &>/dev/null
    cd test.git

    git init "$@"
)

_git_commit() (
    file=${1:?not set}
    data=${2:?not set}
    info=${3:?not set}

    exec &>/dev/null
    cd test.git

    [[ $1 =~ */ ]] && {
        mkdir -p $file
    } || {
        mkdir -p $(dirname $file)
        touch $file
    }
    echo "$data" >> $file

    git add $file
    git commit -m "$info"
)

_git_checkout() (
    exec &>/dev/null
    cd test.git

    git checkout "$@"
)

_git_set_up() (
    mkdir -p "test.git"
    _git_init
    _git_commit 1 1 1
    _git_commit 2 2 2
    _git_tag v0.1
    _git_commit 3 3 3
    _git_checkout -b develop
    _git_commit 4 4 4
    _git_checkout master
)

_git_tear_down() {
    rm -rf "test.git"
}

###############################################################################
#
# Actual Tests
#
###############################################################################

USER=$(id -nu)
HOST=$HOSTNAME

_test_run "Shared dot files deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotfile"
'

_test_run "User based dot files deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
'

_test_run "Host based dot files deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Host based dot files deployment with user based exits" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Host then user based dot file deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
'

_test_run "Fallback host based to shared" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotfile"
'

_test_run "Fallback user based to shared" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotfile"
'

_test_run "Fallback host and user based to shared" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotfile"
'

_test_run "Fallback host and user based deployment to user based" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
'

_test_run "Fallback host and user based deployment to host based" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Fallback host and user based deployment to host based when __USER and __HOST both there" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" dotsdest
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Backup if destination already exists" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsdest/.dotdir2/"
        "dotsdest/.dotfile2"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
        "dotsdest/.dotdir3/"
        "dotsdest/.dotfile3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
        "dotsdest/.dotdir4/"
        "dotsdest/.dotfile4"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_expr_true "test -d dotsdest/.dotdir1"
    _test_expect_expr_true "test -f dotsdest/.dotfile1"
    _test_expect_expr_true "test -d dotsdest/.dotdir2"
    _test_expect_expr_true "test -f dotsdest/.dotfile2"
    _test_expect_expr_true "test -d dotsdest/.dotdir3"
    _test_expect_expr_true "test -f dotsdest/.dotfile3"
    _test_expect_expr_true "test -d dotsdest/.dotdir4"
    _test_expect_expr_true "test -f dotsdest/.dotfile4"
'
_test_run "Backup if destination already exists with --force option" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsdest/.dotdir2/"
        "dotsdest/.dotfile2"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
        "dotsdest/.dotdir3/"
        "dotsdest/.dotfile3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
        "dotsdest/.dotdir4/"
        "dotsdest/.dotfile4"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
    )
    _make_layer "${repo_layer[@]}"
    _test_expect_missing "dotsdest/.dotploy/backup"
    dotploy.sh deploy --force "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotploy/backup"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir1"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile1"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir2"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile2"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir3"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile3"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir4"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile4"
'

_test_run "Whether __IGNORE works as expected" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__IGNORE"
        "dotsrepo/__DOTDIR/dir1/"
        "dotsrepo/__DOTDIR/file1"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__USER.$USER/dir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/file2"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/dir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/file3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/dir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/file4"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
    )
    _make_layer "${repo_layer[@]}"
    echo "^dir1$"  >> "dotsrepo/__DOTDIR/__IGNORE"
    echo "^file1$" >> "dotsrepo/__DOTDIR/__IGNORE"
    echo "^dir2$"  >> "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
    echo "^file2$" >> "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
    echo "^dir3$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
    echo "^file3$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
    echo "^dir4$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
    echo "^file4$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_missing "dotsdest/dir1"
    _test_expect_missing "dotsdest/file1"
    _test_expect_missing "dotsdest/dir2"
    _test_expect_missing "dotsdest/file2"
    _test_expect_missing "dotsdest/dir3"
    _test_expect_missing "dotsdest/file3"
    _test_expect_missing "dotsdest/dir4"
    _test_expect_missing "dotsdest/file4"
    _test_expect_symlink "dotsdest/.dotdir1"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotfile1"
    _test_expect_symlink "dotsdest/.dotdir2"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2"
    _test_expect_symlink "dotsdest/.dotfile2" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
    _test_expect_symlink "dotsdest/.dotdir3"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3"
    _test_expect_symlink "dotsdest/.dotfile3" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
    _test_expect_symlink "dotsdest/.dotdir4"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4"
    _test_expect_symlink "dotsdest/.dotfile4" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
'

_test_run "Directory contains __KEEPED deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotdir1"
    _test_expect_directory "dotsdest/.dotdir2"
    _test_expect_directory "dotsdest/.dotdir3"
    _test_expect_directory "dotsdest/.dotdir4"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Destination of the directory conatains __KEEPED exists as a file" '
    repo_layer=(
        "dotsdest/.dotdir1"
        "dotsdest/.dotdir2"
        "dotsdest/.dotdir3"
        "dotsdest/.dotdir4"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotdir1"
    _test_expect_directory "dotsdest/.dotdir2"
    _test_expect_directory "dotsdest/.dotdir3"
    _test_expect_directory "dotsdest/.dotdir4"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Destination of the directory conatains __KEEPED exists as a directory" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotdir2/"
        "dotsdest/.dotdir3/"
        "dotsdest/.dotdir4/"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotdir1"
    _test_expect_directory "dotsdest/.dotdir2"
    _test_expect_directory "dotsdest/.dotdir3"
    _test_expect_directory "dotsdest/.dotdir4"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Whether __IGNORE and __KEEPED works together" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir1/__IGNORE"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/dir/"
        "dotsrepo/__DOTDIR/.dotdir1/file"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__IGNORE"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/dir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/file"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/dir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/file"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/dir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/file"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/.dotdir1/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/.dotdir1/__IGNORE"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__IGNORE"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__IGNORE"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__IGNORE"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_missing "dotsdest/.dotdir1/dir"
    _test_expect_missing "dotsdest/.dotdir1/file"
    _test_expect_missing "dotsdest/.dotdir2/dir"
    _test_expect_missing "dotsdest/.dotdir2/file"
    _test_expect_missing "dotsdest/.dotdir3/dir"
    _test_expect_missing "dotsdest/.dotdir3/file"
    _test_expect_missing "dotsdest/.dotdir4/dir"
    _test_expect_missing "dotsdest/.dotdir4/file"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Use __IGNORE ignore directory contains __KEEPED" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__IGNORE"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    echo "^.dotdir1$" >> "dotsrepo/__DOTDIR/__IGNORE"
    echo "^.dotdir2$" >> "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
    echo "^.dotdir3$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
    echo "^.dotdir4$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_missing "dotsdest/.dotdir1"
    _test_expect_missing "dotsdest/.dotdir2"
    _test_expect_missing "dotsdest/.dotdir3"
    _test_expect_missing "dotsdest/.dotdir4"
'

_test_run "Local file/directory deploy" '
    repo_layer=(
        "normaldir/"
        "normalfile"
        "normaldir/normalfile"
        "dotsdest/normaldir1/"
        "dotsdest/normalfile1"
        "dotsrepo/__DOTDIR/.dotfile1.__SRC"
        "dotsrepo/__DOTDIR/.dotfile2.__SRC"
        "dotsrepo/__DOTDIR/.dotfile3.__SRC"
        "dotsrepo/__DOTDIR/.dotfile4.__SRC"
        "dotsrepo/__DOTDIR/.dotfile5.__SRC"
        "dotsrepo/__DOTDIR/.dotfile6.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    ( cd dotsdest/normaldir1; ln -s ../normalfile1 normalfile1 )
    echo "$TEST_FIELD/normaldir" >> "dotsrepo/__DOTDIR/.dotfile1.__SRC"
    echo "$TEST_FIELD/normalfile" >> "dotsrepo/__DOTDIR/.dotfile2.__SRC"
    echo "$TEST_FIELD/normaldir/normalfile" >> "dotsrepo/__DOTDIR/.dotfile3.__SRC"
    echo "normaldir1" > "dotsrepo/__DOTDIR/.dotfile4.__SRC"
    echo "normalfile1" > "dotsrepo/__DOTDIR/.dotfile5.__SRC"
    echo "normaldir1/normalfile1" > "dotsrepo/__DOTDIR/.dotfile6.__SRC"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/normaldir"
    _test_expect_symlink "dotsdest/.dotfile2" "$TEST_FIELD/normalfile"
    _test_expect_symlink "dotsdest/.dotfile3" "$TEST_FIELD/normaldir/normalfile"
    _test_expect_symlink "dotsdest/.dotfile4" "normaldir1"
    _test_expect_symlink "dotsdest/.dotfile5" "normalfile1"
    _test_expect_symlink "dotsdest/.dotfile6" "normaldir1/normalfile1"
    output=$(dotploy.sh deploy "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_unmatch "$output" "Warning: $TEST_FIELD/dotsdest/.dotfile3 already exists, use --force option to force deploying"
    _test_expect_unmatch "$output" "Warning: $TEST_FIELD/dotsdest/.dotfile4 already exists, use --force option to force deploying"
    _test_expect_unmatch "$output" "Warning: $TEST_FIELD/dotsdest/.dotfile5 already exists, use --force option to force deploying"
'

_test_run "Local file/directory deploy with target missing" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile1.__SRC"
        "dotsrepo/__DOTDIR/.dotfile2.__SRC"
        "dotsrepo/__DOTDIR/.dotfile3.__SRC"
        "dotsrepo/__DOTDIR/.dotfile4.__SRC"
        "dotsrepo/__DOTDIR/.dotfile5.__SRC"
        "dotsrepo/__DOTDIR/.dotfile6.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "$TEST_FIELD/normaldir" > "dotsrepo/__DOTDIR/.dotfile1.__SRC"
    echo "$TEST_FIELD/normalfile" > "dotsrepo/__DOTDIR/.dotfile2.__SRC"
    echo "$TEST_FIELD/normaldir/normalfile" >> "dotsrepo/__DOTDIR/.dotfile3.__SRC"
    echo "normaldir1" > "dotsrepo/__DOTDIR/.dotfile4.__SRC"
    echo "normalfile1" > "dotsrepo/__DOTDIR/.dotfile5.__SRC"
    echo "normaldir1/normalfile1" > "dotsrepo/__DOTDIR/.dotfile6.__SRC"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/normaldir"
    _test_expect_symlink "dotsdest/.dotfile2" "$TEST_FIELD/normalfile"
    _test_expect_symlink "dotsdest/.dotfile3" "$TEST_FIELD/normaldir/normalfile"
    _test_expect_symlink "dotsdest/.dotfile4" "normaldir1"
    _test_expect_symlink "dotsdest/.dotfile5" "normalfile1"
    _test_expect_symlink "dotsdest/.dotfile6" "normaldir1/normalfile1"
'

_test_run "Remote git repository deploy" '
    _git_set_up
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "git+file://$TEST_FIELD/test.git" > "dotsrepo/__DOTDIR/.dotfile.__SRC"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotfile" "$TEST_FIELD/dotsdest/.dotploy/vcs/test.dotfile"
    output=$(dotploy.sh deploy "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_unmatch "$output" "Warning: $TEST_FIELD/dotsdest/.dotfile already exists, use --force option to force deploying"
'

_test_run "Remote git repository deploy with differnt HEAD" '
    _git_set_up
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "git+file://$TEST_FIELD/test.git" > "dotsrepo/__DOTDIR/.dotfile.__SRC"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _git_checkout develop
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_expr_true "test $(cd dotsdest/.dotploy/vcs/test.dotfile;git rev-parse --short HEAD) = $(cd test.git;git rev-parse --short develop)"
'

_test_run "Remote git repository deploy with wrong repo url" '
    _git_set_up
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "git+file://$TEST_FIELD/test1.git" > "dotsrepo/__DOTDIR/.dotfile.__SRC"
    output=$(dotploy.sh deploy "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "ERROR: Failed to clone repository '\''$TEST_FIELD/test1.git'\'' to '\''$TEST_FIELD/dotsdest/.dotploy/vcs/test1.dotfile'\''."
    _test_expect_missing "dotsdest/.dotfile"
'

_test_run "Remote git repository deploy with the location to be cloned to exists" '
    _git_set_up
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "git+file://$TEST_FIELD/test.git" > "dotsrepo/__DOTDIR/.dotfile.__SRC"
    (
        mkdir -p dotsdest/.dotploy/vcs/
        cd dotsdest/.dotploy/vcs/
        touch test.dotfile
    )
    output=$(dotploy.sh deploy "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    bakdir=dotsdest/.dotploy/backup/$(ls -1 --color=none dotsdest/.dotploy/backup)
    _test_expect_match "$output" "Warning: '\''$TEST_FIELD/dotsdest/.dotploy/vcs/test.dotfile'\'' is already there, backup to '\''$TEST_FIELD/$bakdir'\''."
    _test_expect_exists $bakdir/test.dotfile
'

_test_run "Remote git repository deploy with the existing repo upstream incorrect" '
    _git_set_up
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "git+file://$TEST_FIELD/test.git" > "dotsrepo/__DOTDIR/.dotfile.__SRC"
    (
        mkdir -p dotsdest/.dotploy/vcs/
        cd dotsdest/.dotploy/vcs/
        git clone $TEST_FIELD/test.git test.dotfile &>/dev/null
        cd test.dotfile
        git remote set-url --add origin $TEST_FIELD/test1.git
    )
    output=$(dotploy.sh deploy "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    bakdir=dotsdest/.dotploy/backup/$(ls -1 --color=none dotsdest/.dotploy/backup)
    _test_expect_match "$output" "Warning: '\''$TEST_FIELD/dotsdest/.dotploy/vcs/test.dotfile'\'' is already there, backup to '\''$TEST_FIELD/$bakdir'\''."
    _test_expect_directory $bakdir/test.dotfile
'

_test_run "Remote git repository deploy with the existing repo upstream being dead" '
    _git_set_up
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "git+file://$TEST_FIELD/test.git" > "dotsrepo/__DOTDIR/.dotfile.__SRC"
    (
        mkdir -p dotsdest/.dotploy/vcs/
        cd dotsdest/.dotploy/vcs/
        git clone $TEST_FIELD/test.git test.dotfile &>/dev/null
    )
    rm -rf $TEST_FIELD/test.git
    output=$(dotploy.sh deploy "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "Warning: Failed to fetch upstream '\''$TEST_FIELD/test.git'\'' in '\''$TEST_FIELD/dotsdest/.dotploy/vcs/test.dotfile'\''."
'

_test_run "Remote git repository deploy with reference specified" '
    _git_set_up
    _git_commit 5/6 6 6
    _git_checkout develop
    _git_commit 7/8 8 8
    _git_checkout master
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotfile1.__SRC"
        "dotsrepo/__DOTDIR/.dotfile2.__SRC"
        "dotsrepo/__DOTDIR/.dotfile3.__SRC"
        "dotsrepo/__DOTDIR/.dotfile4.__SRC"
        "dotsrepo/__DOTDIR/.dotfile5.__SRC"
    )
    _make_layer "${repo_layer[@]}"
    echo "test1::git+file://$TEST_FIELD/test.git#tag=v0.1" > "dotsrepo/__DOTDIR/.dotfile1.__SRC"
    echo "test2::git+file://$TEST_FIELD/test.git#branch=develop" > "dotsrepo/__DOTDIR/.dotfile2.__SRC"
    echo "test3::git+file://$TEST_FIELD/test.git#commit=$(cd test.git;git rev-parse --short v0.1~)" > "dotsrepo/__DOTDIR/.dotfile3.__SRC"
    echo "test4::git+file://$TEST_FIELD/test.git#file=5/6" > "dotsrepo/__DOTDIR/.dotfile4.__SRC"
    echo "test5::git+file://$TEST_FIELD/test.git#branch=develop&file=7/8" > "dotsrepo/__DOTDIR/.dotfile5.__SRC"
    dotploy.sh deploy "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/dotsdest/.dotploy/vcs/test1.dotfile1"
    _test_expect_expr_true "test $(cd dotsdest/.dotploy/vcs/test1.dotfile1;git rev-parse --short HEAD) = $(cd test.git;git rev-parse --short v0.1)"
    _test_expect_symlink "dotsdest/.dotfile2" "$TEST_FIELD/dotsdest/.dotploy/vcs/test2.dotfile2"
    _test_expect_expr_true "test $(cd dotsdest/.dotploy/vcs/test2.dotfile2;git rev-parse --short HEAD) = $(cd test.git;git rev-parse --short develop)"
    _test_expect_symlink "dotsdest/.dotfile3" "$TEST_FIELD/dotsdest/.dotploy/vcs/test3.dotfile3"
    _test_expect_expr_true "test $(cd dotsdest/.dotploy/vcs/test3.dotfile3;git rev-parse --short HEAD) = $(cd test.git;git rev-parse --short v0.1~)"
    _test_expect_symlink "dotsdest/.dotfile4" "$TEST_FIELD/dotsdest/.dotploy/vcs/test4.dotfile4/5/6"
    _test_expect_symlink "dotsdest/.dotfile5" "$TEST_FIELD/dotsdest/.dotploy/vcs/test5.dotfile5/7/8"
    _test_expect_expr_true "test $(cd dotsdest/.dotploy/vcs/test5.dotfile5;git rev-parse --short HEAD) = $(cd test.git;git rev-parse --short develop)"
'

_test_run "Add given file to the dots repo" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsdest/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"
    for i in "${repo_layer[@]}"
    do
        dotploy.sh add $i "dotsrepo" "dotsdest"
    done
    _test_expect_expr_true "test -d dotsrepo/__DOTDIR/.dotdir1"
    _test_expect_symlink "dotsdest/.dotdir1" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/.dotfile1"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotfile1"
    _test_expect_expr_true "test -d dotsrepo/__DOTDIR/.dotdir2"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/.dotdir2/dotfile2"
    _test_expect_symlink "dotsdest/.dotdir2/dotfile2" "$TEST_FIELD/dotsrepo/__DOTDIR/.dotdir2/dotfile2"
'

_test_run "Add given file to the dots repo with --host" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsdest/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"
    for i in "${repo_layer[@]}"
    do
        dotploy.sh add --host $i "dotsrepo" "dotsdest"
    done
    _test_expect_expr_true "test -d dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir1"
    _test_expect_symlink "dotsdest/.dotdir1" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile1"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir2/dotfile2"
    _test_expect_symlink "dotsdest/.dotdir2/dotfile2" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir2/dotfile2"
'

_test_run "Add given file to the dots repo with --user" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsdest/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"
    for i in "${repo_layer[@]}"
    do
        dotploy.sh add --user $i "dotsrepo" "dotsdest"
    done
    _test_expect_expr_true "test -d dotsrepo/__DOTDIR/__USER.$USER/.dotdir1"
    _test_expect_symlink "dotsdest/.dotdir1" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/__USER.$USER/.dotfile1"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotfile1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/dotfile2"
    _test_expect_symlink "dotsdest/.dotdir2/dotfile2" "$TEST_FIELD/dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/dotfile2"
'

_test_run "Add given file to the dots repo with --user and --host" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsdest/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"
    for i in "${repo_layer[@]}"
    do
        dotploy.sh add --host --user $i "dotsrepo" "dotsdest"
    done
    _test_expect_expr_true "test -d dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir1"
    _test_expect_symlink "dotsdest/.dotdir1" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile1"
    _test_expect_symlink "dotsdest/.dotfile1" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile1"
    _test_expect_expr_true "test -f dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir2/dotfile2"
    _test_expect_symlink "dotsdest/.dotdir2/dotfile2" "$TEST_FIELD/dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir2/dotfile2"
'

_test_run "Add given file which is not in the dots dest" '
    repo_layer=(
        ".dotdir1/"
        ".dotfile1"
        ".dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"

    output=$(dotploy.sh add ".dotdir1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not in dest home"
    _test_expect_expr_true "test -d .dotdir1"

    output=$(dotploy.sh add ".dotfile1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not in dest home"
    _test_expect_expr_true "test -f .dotfile1"

    output=$(dotploy.sh add ".dotdir2/dotfile2" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not in dest home"
    _test_expect_expr_true "test -f .dotdir2/dotfile2"
'

_test_run "Add given file to the dots repo with the target already exists" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsdest/.dotdir2/dotfile2"
        "dotsrepo/__DOTDIR/.dotdir2/dotfile2"
        "dotsdest/.dotfile3"
        "dotsrepo/__DOTDIR/.dotfile3"
    )
    _make_layer "${repo_layer[@]}"

    output=$(dotploy.sh add "dotsdest/.dotdir1/" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target already exists"
    _test_expect_expr_true "test -d dotsdest/.dotdir1"

    output=$(dotploy.sh add "dotsdest/.dotfile1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target already exists"
    _test_expect_expr_true "test -f dotsdest/.dotfile1"

    output=$(dotploy.sh add "dotsdest/.dotdir2/dotfile2" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target already exists"
    _test_expect_expr_true "test -f dotsdest/.dotdir2/dotfile2"

    dotploy.sh add --force "dotsdest/.dotfile3" "dotsrepo" "dotsdest"
    _test_expect_expr_true "test -h dotsdest/.dotfile3"
'

_test_run "Remove given file from linking to dots repo" '
    repo_layer=(
        "dotsdest/.dotdir2/"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsrepo/__DOTDIR/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"

    ln -s $(realpath "dotsrepo/__DOTDIR/.dotdir1/") "dotsdest/.dotdir1"
    dotploy.sh remove "dotsdest/.dotdir1" "dotsrepo" "dotsdest"
    _test_expect_expr_true "test ! -h dotsdest/.dotdir1"

    ln -s $(realpath "dotsrepo/__DOTDIR/.dotfile1") "dotsdest/.dotfile1"
    dotploy.sh remove "dotsdest/.dotfile1" "dotsrepo" "dotsdest"
    _test_expect_expr_true "test ! -h dotsdest/.dotfile1"

    ln -s $(realpath "dotsrepo/__DOTDIR/.dotdir2/dotfile2") "dotsdest/.dotdir2/dotfile2"
    dotploy.sh remove "dotsdest/.dotdir2/dotfile2" "dotsrepo" "dotsdest"
    _test_expect_expr_true "test ! -h dotsdest/.dotdir2/dotfile2"
'

_test_run "Remove given file which is not a link" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsdest/.dotdir2/dotfile2"
        "dotsrepo/__DOTDIR/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"

    output=$(dotploy.sh remove "dotsdest/.dotdir1/" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target is not a link"

    output=$(dotploy.sh remove "dotsdest/.dotfile1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target is not a link"

    output=$(dotploy.sh remove "dotsdest/.dotdir2/dotfile2" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target is not a link"
'

_test_run "Remove given file which is not in the dots dest" '
    repo_layer=(
        ".dotdir2/"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsrepo/__DOTDIR/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"

    ln -s $(realpath "dotsrepo/__DOTDIR/.dotdir1/") ".dotdir1"
    output=$(dotploy.sh remove ".dotdir1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not in dest home"

    ln -s $(realpath "dotsrepo/__DOTDIR/.dotfile1") ".dotfile1"
    output=$(dotploy.sh remove ".dotfile1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not in dest home"

    ln -s $(realpath "dotsrepo/__DOTDIR/.dotdir2/dotfile2") ".dotdir2/dotfile2"
    output=$(dotploy.sh remove ".dotdir2/dotfile2" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not in dest home"
'

_test_run "Remove given file which is not linking to the dots repo" '
    repo_layer=(
        ".dotdir1/"
        ".dotfile1"
        ".dotdir2/dotfile2"
        "dotsdest/.dotdir2/"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsrepo/__DOTDIR/.dotdir2/dotfile2"
    )
    _make_layer "${repo_layer[@]}"

    ln -s $(realpath ".dotdir1/") "dotsdest/.dotdir1"
    output=$(dotploy.sh remove "dotsdest/.dotdir1/" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not link to our repo"

    ln -s $(realpath ".dotfile1") "dotsdest/.dotfile1"
    output=$(dotploy.sh remove "dotsdest/.dotfile1" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not link to our repo"

    ln -s $(realpath ".dotdir2/dotfile2") "dotsdest/.dotdir2/dotfile2"
    output=$(dotploy.sh remove "dotsdest/.dotdir2/dotfile2" "dotsrepo" "dotsdest" 2>&1) && echo "$output"
    _test_expect_match "$output" "target not link to our repo"
'

_test_done
