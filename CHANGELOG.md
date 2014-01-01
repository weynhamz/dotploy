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
