
## v0.9 ( 2023-??-?? )

* 

## v0.8 ( 2023-03-15 )

* Promotion (`promote` and `run --auto-promote`):
  * Fix `--no-comment` for promotion that was not used
  * Add argument `--no-exit` to `promote`, to promote everything except the
    exit code (so that the test will still fail with `exitcode`)
  * Don't promote failing `AT_CHECK` with `run-if-fail` or `run-if-pass`
* Configuration file:
  * New config option 'project.run_from' that specifies where `_autofonce/`
    should be created: `build` for build directory (default), `source` for
    source directory or `config` for configuration file directory
* Command Arguments and Behavior:
  * Support for range of test ids like `1-10` or `10-`
  * Exit with non-zero status on failed tests
  * If testsuite location is a directory instead of a file, scan all directoies
    and sub-directories for files `*.at` containing tests, with copying enabled
    (`AT_COPY_ALL([true])`).
  * New option `-o LOGFILE` to specify the log file
  * New command `autofonce config` to print the currently read config
  * New options `-T <FILE.at>`, `-E <env.sh>` and `-I <path>` to describe a
    testsuite directly from the command-line
  * Option `-k KEYWORDS`: if a keyword starts is negated with `-`, then tests
    matching that keyword will not be executed (same as `--not`)
* Improved version of `_autofonce/results.log`:
  * Include all files from failed checks and honor captured files
  * New option `captured_files` in `autofonce.toml` to include some project files
* Standard Macro Language:
  * Implements `AT_FAIL_IF([shell-cond])`
  * To conform with namespace rules for `autoconf`, all macros are supported
    with both a `AT_` and `AF_` prefix, and `autofonce` will promote `autofonce`
    specific macros with the `AF_` prefix, while using the `AT_` prefix for
    `autoconf` compatible macros
* Macro language extensions (default is `AF_`, but `AT_` is accepted:
  * Skip macro definitions with `AC_DEFUN/m4_define`. This is currently
    mostly done to allow the definition of: `AC_DEFUN([AF_ENV],
    [$1])`. Print a warning for discarding the macro definition, except
    for `AF_ENV`.
  * Add `AF_ENV([env])` as a way to define a specific environment for the test
    (such as environment variables).
    * At toplevel, declarations by `AF_ENV` are added in the `autofonce_env.sh`
      file of every test.
    * At test level, declarations are added directly in all following
      check scripts
  * Add `AF_COPY(files)` to copy files from the test source directory to the
      test run directory
  * Add `AF_LINK(files)`, same as `AF_COPY`, but symlink instead of copy
  * Add `AF_COPY_ALL([true|false])`. If true, used before tests, make tests
    copy all non .at files in their directory as if `AF_COPY` had been used.
    If false, disable copying files for following tests.
  * Add `AF_LINK_ALL()`, same as `AF_COPY_ALL`, but symlink instead of copy
  * Add `AF_SUBST(variables)` to replace occurrences of these env variables
    in the stdout/stderr. A special case is `AUTOFONCE` that replaces
    `${AUTOFONCE_RUN_DIR}/${TEST_ID}`, `${AUTOFONCE_BUILD_DIR}` and
    `${AUTOFONCE_SOURCE_DIR}`.
* Add a testsuite in `test/testsuite.at`

## v0.7 ( 2023-02-09 )

* Add option `--auto-promote MAX` to `autofonce run` to iterate
  run/promote until all changes have been promoted or a maximal number of
  MAX iterations
* Add option `--failures REASON` to select tests matching a specific reason
  like `exitcode`, `stdout` or `stderr`
* Add config option `build_dir_candidates` (default to `[ "_build" ]`) to
  automatically try to find build anchors from outside the build dir
  using alternative candidates

## v0.6 ( 2023-02-05 )

* Replace `autofonce.env` by a configuration file:

  * Configuration can be stored in `autofonce.toml` (typically not committed in
    sources) or `.autofonce` (committed in sources)
  * `autofonce` will lookup `autofonce.toml` first, and `.autofonce` if not
    found, and fail if none is found
  * `autofonce init` will create a `autofonce.toml` in the local directory.
  * A `autofonce.toml` file can be renamed to `.autofonce` and committed.
  * The configuration provides:
    * `[testsuites]` section: aliases for testsuites, with the testsuite file,
      the path for included files, and the env name
    * `[envs]` section: possibility to define different envs (included in tests
      scripts) for different testsuites
    * `source_anchors` and `build_anchors` are used to locate the project source
      dir and the project build dir in the upper directories
  * `autofonce` defines several variables at the beginning of test scripts envs:
    * `AUTOFONCE_TESTSUITE`: name of the testsuite
    * `AUTOFONCE_RUN_DIR`: directory where tests are run (containing `_autofonce/)
    * `AUTOFONCE_SOURCE_DIR`: source directory of the project (root/top dir)
    * `AUTOFONCE_BUILD_DIR`: build directory of the project

* The *run-dir* (the directory that will contain the `_autofonce/` subdir) is
  determined by:
  * the directory containing the file `autofonce.toml`, or
  * the build directory as defined by the anchors in the `.autofonce` file


## v0.5 ( 2023-02-04 )

* Add subcommand `autofonce promote` to update tests files with current
  results. This command can be applied using standard filters. By default,
  display a diff of changes to be performed. Use `--apply` to actually
  perform the tests.
* Add selector --failed to run only previously failed tests
* Scripts are run with `AUTOFONCE_SUITE_DIR` and `AUTOFONCE_SUITE_FILE`
   env variables (to locate and identify the `testsuite.at` file)
* Rename `_autotest/` dir to `_autofonce/` dir
* Simplify default `gnucobol.env` to use `atconfig` and `atlocal`: slower
   but probably more portable

## v0.4 ( 2023-02-02 )

* Improve m4 parsing
* display nchecks performed
* allow if/then/else within tests
* min-edition set to 4.10

## v0.3 ( 2023-01-28 )

* add `autofonce new` to create new tests

## v0.2 ( 2023-01-28 )

* Improved documentation

## v0.1 ( 2023-01-28 )

* Initial commit
