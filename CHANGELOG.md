DONE dry-run
DONE diff
update notification
support _CATE
support inteactive
support autodeploy
support easy manuniplate the dot files repo
support easy deploy on new machine
need to be able to update the files from a git source
need to be able to warn if have local changes
upon removal, there are some files that is not existed
Need to be able to replace the file in the repo with the curent target file
Need to be able to remove the file in the repo
Need to be able to add the current file into the host override
Need to prompt to push current changes to upstream
Need to add the ability to run post command after colone a git repo
NEED to be able to preserve/warn local chagnes
FOR GIT REMOTE REPO, needs a way to detect if there is local chagnes

Version 0.3.4
-------------

    * More clear nested verbose output
    * Full Git HEAD/branch synchronization support
    * Add '--vcs-clean' option to clean up VCS database

Version 0.3.3
-------------

    * Hotfix: Fix the wrong HEAD file location

Version 0.3.2
-------------

    * Standalone version improvements
    * Fix checking target deployed from '.__SRC' file
    * Symlink to a local path, the existence is irrelevant

Version 0.3.1
-------------

    * Doc updates, typo fixes
    * Standalone version improvements

Version 0.3
-----------

    * New dependency: bashLib
    * Use 'make' for building
    * Redesigned test structure
    * Ability to manage dots repo
    * Ability to deploy from VCS or local path
    * '$HOME/.dotploy/config' configuration support
    * Confilcted files while deploying will be skipped
      now, use '--force' option to backup first

Version 0.2
-----------

    * Plenty of bugfixes
    * Remove command line option '-d'
    * Remove command line option '-p'
    * Add GUN-style long command line options support
    * Show processing details only when '-v' is given
    * Backups now is stored in '.dotploy/' directory under
      deployment destination

Version 0.1
-----------

    * Host based dot files deployment
    * User based dot files deployment
    * Dead symlinks checking and cleaning
