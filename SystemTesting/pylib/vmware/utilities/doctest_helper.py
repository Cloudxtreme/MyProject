#!/usr/bin/python

"""
Helpers for doctest-based testing.
"""

import doctest
import inspect
import sys

# To help avoid circular import issues it is recommended to never import
# modules from lib here and instead stick to standard Python modules.


def run_testmod(globals_=None, locals_=None, argv=None, exit_after=True,
                force=False, default_options=None, **doctest_kw):
    """
    If the script was run with '--test' option run doctest module tests
    and exit the script.

    Exit Code
        0  No tests failed or no tests to run.
        1  One or more tests failed.

    If the script was run with '--testone <module|func>' option run doctest for
    that specific module (or) class (or) function only and exit the script with
    zero as exit code

    Optionally set exit_after=False to return the boolean result to the caller
    instead of exiting the script.

    Set force=True to run this without requiring '--test' option when the
    script was run.
    """
    if argv is None:
        argv = sys.argv
    name = None
    if '--test' in argv:
        force = True
    if '--testone' in argv:
        force = True
        idx = argv.index('--testone')
        if len(argv) - 1 > idx:
            name = argv[idx + 1]
        frame = inspect.currentframe()
        if globals_ is None:
            globals_ = frame.f_back.f_globals
        if locals_ is None:
            locals_ = frame.f_back.f_locals

    if '-v' in argv:
        doctest_kw['verbose'] = True

    if not force:
        return
    failures, total = do_testmod(globals_=globals_, locals_=locals_, name=name,
                                 default_options=default_options, **doctest_kw)
    if exit_after:
        sys.exit(bool(failures))
    else:
        return failures, total


def check_testmod(default_options=None, **doctest_kw):
    """
    Runs the doctests, if any fail, raise an exception
    """
    failures, total = do_testmod(default_options=default_options, **doctest_kw)
    if failures:
        raise AssertionError('%d/%d doctests failed' % (failures, total))


def do_testmod(globals_=None, locals_=None, name=None,
               default_options=None, **doctest_kw):
    """
    Default options can be any of the doctest flags combinations (as
    integer) or True/False.  None defaults to True.  If True, uses
    ELLIPSIS and NORMALIZE_WHITESPACE, otherwise uses no options.
    """
    NO_OPTIONS = 0
    STANDARD_OPTIONS = doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE
    if default_options in (None, True):
        default_options = STANDARD_OPTIONS
    elif default_options is False:
        default_options = NO_OPTIONS
    else:
        default_options = int(default_options)
    doctest_kw.setdefault('optionflags', NO_OPTIONS)
    doctest_kw['optionflags'] |= default_options
    if name:
        doctest.run_docstring_examples(
            eval(name, globals_, locals_), globals_, name=name, **doctest_kw)
        return [], 0
    else:
        return doctest.testmod(**doctest_kw)
