Dotploy
=======

This script was designed for ease of the dot files deployment under $HOME
directory for mutiple users on several hosts.

Some common dot files are shared by different users and hosts. Host specific
dot files can be placed under \_\_HOST.$HOSTNAME directory, user specific dot
files can be placed under \_\_USER.$USER or \_\_HOST.$HOSTNAME/\_\_USER.$USRE
direcotry. The deeper nested file with same name has a higher priority.

Developed and distributed under GPLv2 or later version.

How To Use it?
--------------

    dotploy.sh [-d] <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]
    dotploy.sh [-p] <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

    Options:

        -d  deploy dotfiles
        -p  prune broken symlinks

    The <destination_of_the_deployment> is optional. If it is absent, current
    $HOME will be used.

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
