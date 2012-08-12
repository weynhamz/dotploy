Usage
-----

    dotploy.sh [OPTIONS] PATH_TO_THE_DOTFILES_REPO [DESTINATION_OF_THE_DOT_FILES]

    Options:
        -p  prune broken symlinks according to the last dotploy.log
        -d  deploy dotfiles

DESTINATION_OF_THE_DOT_FILES is optional, if absent, current $HOME will be used.

Summary
-------

This is a bash only script designed to help easy the $HOME dot files deployment
acrossing several hosts. All the hosts share some common dot files. Host specific
dot files are located under __HOST.$HOSTNAME directory, user specfic files are
located under \_\_USER.$USER or \_\_HOST.$HOSTNAME/\_\_USER.$USRE direcotry, the later
one with same name can overwrite the earlier one.


Developed under GPLv2 or later version.

Dotfils Repo Structure
----------------------

The dot files structure must be keepd as same as they are in the original location.

    DOTFILES_REPO
        |
        |--------__BACKUP
        |       |
        |       |--------$HOSTNAME
        |       |       |
        |       |       |--------2012.03.12.14.05.03
        |       |       |        ^^^^^^^^^^^^^^^^^^^
        |       |       |        this is the backup directory of the conflict files
        |       |       |        while deploying.
        |       |       |
        |       |       |--------......
        |
        |--------__UNUSED
        |        ^^^^^^^^
        |        this directory is no usesd, intend to place the dot files that are
        |        nolonger used, but may be need oneday.
        |
        |--------__DOTDIR
        |       |
        |       |--------__HOST.$HOSTNAME
        |       |       |
        |       |       |--------__USER.$USER
        |       |       |       |
        |       |       |       |--------.dotfile1
        |       |       |       |
        |       |       |       |--------.dotfile2
        |       |       |       |
        |       |       |       |--------......
        |       |       |       |
        |       |       |       |--------.dotdir1
        |       |       |       |       |
        |       |       |       |       |--------__KEEPED
        |       |       |       |                ^^^^^^^^
        |       |       |       |                this means this directory shoulde not be deployed, instead,
        |       |       |       |                deploy its contents to the corresponding path under $HOME.
        |       |       |       |
        |       |       |       |--------.dotdir2
        |       |       |       |
        |       |       |       |--------......
        |       |       |
        |       |       |
        |       |       |--------.dotfile1
        |       |       |
        |       |       |--------.dotfile2
        |       |       |
        |       |       |--------......
        |       |       |
        |       |       |--------.dotdir1
        |       |       |       |
        |       |       |       |--------__KEEPED
        |       |       |                ^^^^^^^^
        |       |       |                this means this directory shoulde not be deployed, instead,
        |       |       |                deploy its contents to the corresponding path under $HOME.
        |       |       |
        |       |       |--------.dotdir2
        |       |       |
        |       |       |--------......
        |       |
        |       |--------__USER.$USER
        |       |       |
        |       |       |--------.dotfile1
        |       |       |
        |       |       |--------.dotfile2
        |       |       |
        |       |       |--------......
        |       |       |
        |       |       |--------.dotdir1
        |       |       |       |
        |       |       |       |--------__KEEPED
        |       |       |                ^^^^^^^^
        |       |       |                this means this directory shoulde not be deployed, instead,
        |       |       |                deploy its contents to the corresponding path under $HOME.
        |       |       |
        |       |       |--------.dotdir2
        |       |       |
        |       |       |--------......
        |       |
        |       |--------.dotfile1
        |       |
        |       |--------.dotfile2
        |       |
        |       |--------......
        |       |
        |       |--------.dotdir1
        |       |       |
        |       |       |--------__KEEPED
        |       |                ^^^^^^^^
        |       |                this means this directory shoulde not be deployed, instead,
        |       |                deploy its contents to the corresponding path under $HOME.
        |       |
        |       |--------.dotdir2
        |       |
        |       |--------......
        |
        |--------.dotfile1
        |
        |--------.dotfile2
        |
        |--------......
        |
        |--------.dotdir1
        |       |
        |       |--------__KEEPED
        |                ^^^^^^^^
        |                this means this directory shoulde not be deployed, instead,
        |                deploy its contents to the corresponding path under $HOME.
        |
        |--------.dotdir2
        |
        |--------......

Copyright
---------

Techlive Zheng [techlivezheng at gmail.com] 2012
