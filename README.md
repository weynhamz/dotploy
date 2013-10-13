Dotploy
=======

This script is designed for ease of deploying the dot files to `$HOME` directory
for mutiple users on several hosts.

Common dot files needed to be shared with different users on different hosts
could be placed in the root directory of the dots repo. Host specific dot files
could be placed under `__HOST.$HOSTNAME` directory, and user specific dot files
could be placed under `__USER.$USER` or `__HOST.$HOSTNAME/__USER.$USRE`
direcotry. The file in the specified host or user directory with same name has
higher priority.

It is also possible to deploy from other places or VCS sources(currently, only
Git is supported). If a file in the dots repo has suffix `.__SRC`, it will be
recognized as a record file which holds the URL to the real target. The URL is
formed by three components as `folder::url#fragment`, and each component is
explained as following:

    folder:: (optional)
        Specifies an alternate folder name for downloading the VCS source into.
        If absent, dotploy will try to use the best name, usually the repo's
        name or the directory name of the repo extracted from URL string.

    url
        The URL to the VCS repository. The VCS name must be included in the URL
        protocol in order to let dotploy recognize this as a VCS source. If the
        protocol does not contain the VCS name, it can be added by prefixing
        the URL with vcs+. For example, using a Git repository over HTTPS would
        have a source URL in the form: `git+https://....`

    #fragment (optional)
        Allows specifying tag/branch/revision to checkout from the VCS, or the
        relative path of a file from the VCS to be linked to.

        For example, to checkout a given revision, the format would be
        `url#revision=123&file=a/b/c`.

        The available fragments depends on the VCS being used.

        Common:

            file - relative path to a file in the VCS repository

        For Git:

            tag - Git tag to checkout
            branch - Git branch to checkout
            commit - Git commit to checkout

The VCS source will be downloaded to `.dotploy/vcs` under your deploymet
destination.

Developed and distributed under GPLv2 or later version.

How To Use it?
--------------

    Usage:

        dotploy.sh <path_to_the_dotfiles_repo> [<destination_of_the_deployment>]

    Options:

        -h, show help information
        -v, be verbose about the process

    The argument `<destination_of_the_deployment>` is optional. If it is absent,
    then current `$HOME` directory will be used.

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
        |       |--------.dotfile.__SRC
        |       |        ^^^^^^^^^^^^^^
        |       |        Deploy from the location decribed in this file.
        |       |
        |       |--------.dotdir1
        |       |       |
        |       |       |--------__KEEPED
        |       |       |        ^^^^^^^^
        |       |       |        This means this directory shoulde not be
        |       |       |        symlinked, instead, deploy its contents
        |       |       |        to the corresponding location under the
        |       |       |        destination.
        |       |
        |       |--------.dotdir2
        |       |
        |       |--------......
        |       |
        |       |--------.dotfile1
        |       |
        |       |--------.dotfile2
        |       |
        |       |--------......
        |       |
        |       |--------__USER.$USER
        |       |       |
        |       |       |--------.dotdir1
        |       |       |       |
        |       |       |       |--------__KEEPED
        |       |       |
        |       |       |--------.dotdir2
        |       |       |
        |       |       |--------......
        |       |       |
        |       |       |--------.dotfile1
        |       |       |
        |       |       |--------.dotfile2
        |       |       |
        |       |       |--------......
        |       |
        |       |--------__HOST.$HOSTNAME
        |       |       |
        |       |       |--------__USER.$USER
        |       |       |       |
        |       |       |       |--------.dotdir1
        |       |       |       |       |
        |       |       |       |       |--------__KEEPED
        |       |       |       |
        |       |       |       |--------.dotdir2
        |       |       |       |
        |       |       |       |--------......
        |       |       |       |
        |       |       |       |--------.dotfile1
        |       |       |       |
        |       |       |       |--------.dotfile2
        |       |       |       |
        |       |       |       |--------......
        |       |       |
        |       |       |
        |       |       |--------.dotdir1
        |       |       |       |
        |       |       |       |--------__KEEPED
        |       |       |
        |       |       |--------.dotdir2
        |       |       |
        |       |       |--------......
        |       |       |
        |       |       |--------.dotfile1
        |       |       |
        |       |       |--------.dotfile2
        |       |       |
        |       |       |--------......
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
