Import Sorter
=============

Checks that the imports in all ActionScript files are sorted alphabetically, and sorts them on request. Each top-level package (e.g. 'flash', 'starling') gets its own block, separated by a blank line.

    util/import_sorter/import_sorter.rb          # check library, tests and samples
    util/import_sorter/import_sorter.rb --fix    # sort the imports
    util/import_sorter/import_sorter.rb FILE ... # check only the given files or folders

The exit code is 1 if unsorted imports were found (without `--fix`). The CI runs this check, too.

The pre-commit hook in `.githooks` sorts the imports of all staged files automatically. Claude Code activates it on session start; to use it yourself, run `git config core.hooksPath .githooks`.
