Dotploy
=======

This script is designed for ease of deploying the dot files under $HOME
directory for mutiple users on several hosts.

Common dot files needed to be shared with different users on different hosts
could be placed in the root directory of the dots repo. Host specific dot
files could be placed under `__HOST.$HOSTNAME` directory, and user specific
dot files be placed under `__USER.$USER` or `__HOST.$HOSTNAME/__USER.$USRE`
direcotry. The file in the specified host or user directory with same name
has higher priority.

Developed and distributed under GPLv2 or later version.

How To Use it?
--------------

    dotploy.sh <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

    Options:

        -h  show help information
        -v  be verbose about the process

    The `<destination_of_the_deployment>` is optional. If absent, current `$HOME`
    directory will be used.

    Conflicted files will be backed up into `.dotploy/` directory under your
    deployment destination.

Dot Fils Repo Structure
----------------------

The dot files repo structure must be keepd as the same as they are in the
original location.

    DOTFILES_REPO
        |
        |--------__UNUSED
        |        ^^^^^^^^
        |        This directory is not in use, in which I intend
        |        to place some dot files that are nolonger used,
        |        but might be needed someday.
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
        |       |       |       |                This means this directory
        |       |       |       |                shoulde not be symlinked,
        |       |       |       |                instead, deploy its contents
        |       |       |       |                to the corresponding location
        |       |       |       |                under destination.
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
        |
        |--------.dotdir2
        |
        |--------......

Copyright
---------

Techlive Zheng [techlivezheng at gmail.com] 2012
