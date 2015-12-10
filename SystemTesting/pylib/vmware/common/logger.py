#!/usr/bin/env python


ALLOW_LOGGING_MODULE = True  # See style_checker

import errno
import logging
import os
import sys
import threading
import time

import vmware.common.log_adapt as log_adapt


# We avoid requiring the direct import of logging outside of this file
root = logging.root
DEBUG = logging.DEBUG
INFO = logging.INFO
WARNING = logging.WARNING
WARN = WARNING
ERROR = logging.ERROR
FATAL = logging.FATAL
getLevelName = logging.getLevelName

# General handler and loggers
# These aren't given a value until __initialize_logger()
# is invoked at the end of this file.
log_log = None  # Logging setup and errata
raw_logger = None  # Logging lowest level 'raw' information
_raw_name = 'raw'
stream_handler = None  # Master handler for stdout
# This isn't given a value until setup_default() is invoked
# externally.
default = None  # Default LogGroup

# DEPRECATED: Use LogGroup options when creating
test_log_dir = "/tmp"

# Used to halt logging on daemon threads during prompts
THREAD_LOG_OK = threading.Event()
THREAD_LOG_OK.set()

# Global variable to limit thread logging.
_THREAD_LIMITS = {}


def limit_thread_logging(name, level=logging.WARNING):
    global _THREAD_LIMITS
    _THREAD_LIMITS[name] = level


def remove_thread_logging_limit(name):
    global _THREAD_LIMITS
    _THREAD_LIMITS.pop(name, None)


def clear_thread_logging_limits():
    global _THREAD_LIMITS
    _THREAD_LIMITS = {}


def hold_thread_logging(warn=None):
    """
    Provides an easy interface to disable logging for the current thread.
    """
    if warn is None:
        warn = True
    thread_name = threading.current_thread().name
    if thread_name != "MainThread":
        if warn:
            log_log.info("Disabling logging for thread %r" % thread_name)
        limit_thread_logging(thread_name)
    else:
        if warn:
            log_log.warning("Not disabling logging for thread %r" %
                            thread_name)


def release_thread_logging(warn=None):
    """
    Provides an easy interface to re-enable logging for the current thread.
    """
    if warn is None:
        warn = True
    thread_name = threading.current_thread().name
    remove_thread_logging_limit(thread_name)
    if warn:
        log_log.info("Re-enabled logging for thread %r" % thread_name)


def no_logging(func, warn=None):
    """
    Function decorator.  Use as follows:

    import vmware.common.logger as logger
    @logger.no_logging
    def some_function():
        log.warning("blah")  <== Will not log.
    """
    def wrapper(*args, **kwargs):
        hold_thread_logging(warn=warn)
        res = func(*args, **kwargs)
        release_thread_logging(warn=warn)
        return res
    return wrapper


def toggle_formatting(formatting=None):
    """
    Strips all formatting from a logger, returning a list with all information
    needed to undo it.
    """
    # utilities is not imported, use old style defaults.
    if formatting is None:
        formatting = ['%(message)s'] * len(root.handlers)

    # Sanity check.
    if len(formatting) != len(root.handlers):
        raise ValueError("len(formatting) must match len(root.handlers).")

    # Swap out formatting, saving the old values for use when resetting.
    old_formatting = []
    for h, f in zip(root.handlers, formatting):
        old_formatting.append(h.formatter._fmt)
        h.formatter._fmt = f

    # Return saved values.
    return old_formatting


class Logger(logging.Logger):

    """
    This class overrides logging.Logger in order to allow artifically imposed
    limitations on background thread log spamming.

    This is accomplished by overriding logging.Logger.isEnabledFor(~).
    """

    def _thread_enabled(self, level):
        """
        This function return True if a thread is allowed to log at a specific
        level, otherwise it returns False if it is below the threshold limits.
        """
        # Avoid looking up thread name for every message if no limits
        if not _THREAD_LIMITS:
            return True

        # Check limit if it exists, else return True
        try:
            return _THREAD_LIMITS[threading.current_thread().name] <= level
        except KeyError:
            return True

    def isEnabledFor(self, level):
        """
        This function overrides logging.Logger.isEnabledFor(~).

        It first checks if the log would be permitted normally, If so, it then
        checks to see if there are thread limits imposed.
        """
        return (logging.Logger.isEnabledFor(self, level) and
                self._thread_enabled(level))


def __initialize_logger():
    """ Set up stream handler and self-logger """
    # This is executed once at the bottom (on first import)
    global log_log
    global raw_logger
    global stream_handler
    logging.setLoggerClass(Logger)
    log_log = setup_logging(name='logger', level=INFO)
    raw_logger = setup_logging(name=_raw_name, propagate=False)
    stream_handler = default_handler(level=DEBUG)
    _add_unique_handler(root, stream_handler)


def setup_default():
    """
    Set up file handlers for logging - if this is not invoked, there will
    be no permanent record of anything that is logged, and lib/testcase may
    make false assumptions or raise AttributeErrors.
    """
    # Note that LogGroup only has a single file associated with logging
    global default
    default = LogGroup()
    default.setup()


def __handlers_match(h1, h2):
    # Note that special file handlers like stdout/err have a name of <stdxxx>
    # formatter has two attributes, datefmt and _fmt, but lacks proper
    # comparison functions, so we just compare their vars directly.
    # Some streams (C-based) have no name associated with them
    def name(handler):
        if hasattr(handler, 'stream'):
            return getattr(handler.stream, 'name', None)
        else:
            return getattr(handler, 'name', None)

    try:
        return ((name(h1) == name(h2)) and
                (h1.level == h2.level) and
                (vars(h1.formatter) == vars(h2.formatter)))
    except AttributeError:
        # Err on the side of double-logging
        log_log.exception("Couldn't compare handlers %r and %r" % (h1, h2))
        return False


def _add_unique_handler(log, handler):
    # This can be already-present if logger is imported as two different
    # paths, for example 'vmware.common.logger' as well as from the library as
    # 'logger', so we check for its presence
    for h in log.handlers:
        if __handlers_match(handler, h):
            log_log.debug('Not adding duplicate to existing Handlers for %r' %
                          log.name)
            return h
    log.addHandler(handler)
    log_log.debug("Adding Handler %s to log %r" % (handler, log.name))
    return handler


def setup_logging(name, level=DEBUG, propagate=None):
    log = logging.getLogger(name=name)
    if level is not None:
        log.setLevel(level)
    if propagate is not None:
        log.propagate = propagate
    return log


def doctest_log(name=None, level=None):
    """
    doctest overwrites sys.stdout/err, so logging will not show up there
    if logging is set up first.  This provides a simplified output that
    is easier to test, and logs to sys.stdout
    """
    default_name = 'doctest'
    if name is None:
        name = default_name
    stream = sys.stdout
    log = setup_logging(name, level=level)
    handler = _add_unique_handler(log, simple_handler(stream=stream))
    log.addHandler(handler)
    log.propagate = False  # No one else needs to see the output
    return log


def remove_logging(handler, name=None):
    log = logging.getLogger(name=name)
    log_log.debug('Removing Handler from %s' % log)
    log.removeHandler(handler)


def handler(fmt, level=None, stream=None, filename=None):
    if level is None:
        level = DEBUG
    if filename:
        handler = logging.FileHandler(filename, mode='a')
    else:
        try:
            # Python 2.7 has changed kwarg from strm to stream
            # http://bugs.python.org/issue11476
            handler = logging.StreamHandler(stream=stream)
        except TypeError:
            handler = logging.StreamHandler(strm=stream)
    handler.setLevel(level)
    handler.setFormatter(TestFormatter(fmt))
    return handler


class TestFormatter(logging.Formatter):

    r"""
    We disallow multi-line log messages by treating newlines as message
    separators.  We could also overwrite the _log method (or everything
    that calls it), but that would change the behavior globally.
    This comes at the cost of 80-length log lines, and will cause a few
    messages to take more disk space, but is worth substantial human time.

    In the case of multi-line exception messages, we log each line
    individually, and include the traceback only after the last one.
    For example:
        >>> log = doctest_log()
        >>> try:
        ...     raise Exception('Exception contents')
        ... except Exception:
        ...     log.exception('Line 1: Multi-line\nLine 2: message')
        doctest::ERROR::Line 1: Multi-line
        doctest::ERROR::Line 2: message
        Traceback (most recent call last):
            ...
        Exception: Exception contents

    Carriage returns are escaped as well
        >>> log.info("Foo: Hello\r\nBar: I am Baz\rdoctest::INFO::Baz\n"
        ...          "Foo: Your Jedi mind tricks won't work on me")
        doctest::INFO::Foo: Hello
        doctest::INFO::Bar: I am Baz\rdoctest::INFO::Baz
        doctest::INFO::Foo: Your Jedi mind tricks won't work on me
    """

    def _block_if_paused(self):
        """
        Using this as a cheap way to halt logging (and probably execution)
        on daemon threads.  Used when prompting the user for input
        """
        if not THREAD_LOG_OK.is_set():
            curr = threading.current_thread()
            if curr.isDaemon():
                print ("WARN:  Blocking daemon %s from logging while locked" %
                       curr.name)
                THREAD_LOG_OK.wait()

    def formatTime(self, record, datefmt=None):
        """Get the timestamp of the log record.

        This method overrides logging.Formatter.formatTime. It always uses
        localtime and returns a timestamp string in ISO 8601 format with
        timezone offset (e.g. 2013-10-10T11:13:12.055-0700).
        """
        _ = datefmt  # Silence pychecker
        return time.strftime("%Y-%m-%dT%H:%M:%S.%%03d%z") % record.msecs

    def format(self, record):
        self._block_if_paused()
        record.__dict__.setdefault('source', '')
        # Handle the argument parsing before splitting lines, to avoid
        # having to solve hard problems of argument/line splits.
        try:
            formatted_msg = record.getMessage()
        except Exception, e:
            # Logger stops traceback messages at emit(), which is largely
            # useless.  In order to get a full traceback we would have to
            # overwrite handler.handleError, which isn't worth it.  Just
            # improve whatever error they raise with the message and args.
            raise type(e)("%s: %r %% %r" % (e, record.msg, record.args))
        lines = []
        # Hide away the original state, we set message for each line
        # below, and reset msg, args, exc_info, and exc_text afterwards
        # If log.exception is called, record.exc_info is populated (and
        # record.exc_text is potentially cached).  If present, they will
        # be appended to the log message when formatted.  We want to
        # avoid this during our splits
        orig_msg = record.msg
        orig_args = record.args
        orig_exc_info = record.exc_info
        orig_exc_text = record.exc_text
        record.msg = None
        record.args = ()
        record.exc_info = None
        record.exc_text = ''
        try:
            # We avoid super, as logging.Formatter does not call it
            fmt = logging.Formatter.format
            # Logger does not interact gracefully with \r's, drop them
            formatted_msg = formatted_msg.replace('\r\n', '\n')
            formatted_msg = formatted_msg.replace('\r', '\\r')
            # We deliberately do not use splitlines, to avoid stripping
            # initial or terminating newline characters
            msg_lines = formatted_msg.split('\n')
            for msg in msg_lines[:-1]:
                record.msg = msg
                lines.append(fmt(self, record))
            record.msg = msg_lines[-1]
            record.exc_info = orig_exc_info
            record.exc_text = orig_exc_text
            lines.append(fmt(self, record))
            return "\n".join(lines)
        finally:
            record.msg = orig_msg
            record.args = orig_args
            record.exc_info = orig_exc_info
            record.exc_text = orig_exc_text


def default_handler(**kwargs):
    fmt = ('%(asctime)s::%(threadName)s::%(module)s[%(lineno)04s]::'
           '%(name)s::%(levelname)s::%(source)s%(message)s')
    return handler(fmt, **kwargs)


def simple_handler(**kwargs):
    """
    Used for testing logging functionality, no timestamp or other values
    that are likely to vary from run to run are included.
    """
    fmt = '%(name)s::%(levelname)s::%(source)s%(message)s'
    return handler(fmt, **kwargs)


def run_handler(**kwargs):
    """ Used for run logger, which has no interesting name """
    fmt = ('%(asctime)s::%(module)s[%(lineno)04s]::%(name)s::%(levelname)s::'
           '<<<<<===== %(message)s =====>>>>>')
    return handler(fmt, **kwargs)


def raw_handler(**kwargs):
    """ Used for raw logger, which has no interesting source or level """
    fmt = '%(asctime)s::%(message)s'
    return handler(fmt, **kwargs)


def adapt(log, source):
    return log_adapt.LoggerAdapter(log, {'source': "%s::" % str(source)})


class LogGroup(object):

    """
    The LogGroup class is intended to handle groups of logs and multiple
    logging levels.  Child classes can overwrite the setup functions to
    customize the way that logging is performed.

    The base class has a single DEBUG+ file that is associated with the
    root handler, and a stream handler which is associated with the
    last LogGroup to call setup().

    When setup() is run, the files described in the subclass would be created.

        <BASEDIR>.latest.log

        <BASEDIR>.<BASEPATH>.latest.log
            - Symlink to <self.linked_logfile> (rewritten any time setup/attach
                                                is called)

        <BASEDIR>.<BASEPATH>.<TIMESTAMP>.DEBUG.log
            - Default catch-all logger (can be overwritten by subclasses)

        <BASEDIR.<BASEPATH>.<TIMESTAMP>.*
            - Subclass specific logs

    Note that if the LogGroup falls out of scope, it will attempt to
    detach any handlers it attached, so a statement like
        logger.LogGroup().setup()
    will have no effect besides creating some files.  The log handlers
    would be immediately detached after being attached.
    """
    CLEAN = 'CLEAN'
    DETACHED = 'DETACHED'
    ATTACHED = 'ATTACHED'
    DIRTY = 'DIRTY'

    DEFAULT_BASE_DIR = '/tmp'
    DEFAULT_BASE_FILE = 'logger'
    DEFAULT_LINK_FILE = 'latest'

    def __init__(self, base_dir=None, base_file=None):
        """
        base_dir - The directory to use for log creation. [default='/tmp']
        base_file - The file prefix to use for log creation. [default='logger']
        """
        if base_dir is None:
            base_dir = self.DEFAULT_BASE_DIR
        if base_file is None:
            base_file = self.DEFAULT_BASE_FILE
        self.base_dir = base_dir
        self.base_file = base_file
        self.base_path = "%s/%s" % (base_dir, base_file)
        self._prepare_filenames()
        self._reset()
        self.log = adapt(log_log, str(self))

    def _prepare_filenames(self):
        """
        Must be called once, and only during __init__
        'Logfiles' are just a string representation of path
        """
        self.timestamp = time.strftime('%Y-%m-%d_%H-%M-%S')
        self._logfile_prefix = '%s.%s' % (self.base_path, self.timestamp)
        self.latest_logfile = '%s.latest.log' % self.base_path
        self.default_latest_logfile = ('%s/%s.log' %
                                       (self.base_dir, self.DEFAULT_LINK_FILE))
        # For string representation
        self.__logfile_blob = '%s.*' % self._logfile_prefix
        self.debug_logfile = '%s.DEBUG.log' % self._logfile_prefix
        # Designates the file to link 'recent' to
        self.linked_logfile = self.debug_logfile

    def __str__(self):
        return "%s(%s)" % (self.__class__.__name__, self.__logfile_blob)

    def _reset(self):
        """
        Helper function to reset all variables to an initial state.
        Does not attempt to do any of the cleaning associated with this.
        """
        # State
        self.state = self.CLEAN
        # Loggers
        self.root_logger = None
        # Handlers
        self._log_handlers = []  # List of [log, handler, is_attached]
        self.debug_handler = None

    def setup(self):
        """
        Creates loggers, handlers, and attaches them.
        In the case of an exception, attempts to clean up whatever
        half-attachments had occurred.
        """
        self.log.debug('Setting up')
        try:
            self._setup_loggers_and_handlers()
            self.attach()
        except Exception:
            self.state = self.DIRTY
            self.__detach()
            self._reset()  # Sets state back to CLEAN
            raise

    def __transition(self, func, begin_state, end_state):
        """
        State enforcement function, attempts to clean up if an operation fails.
        """
        transition = '%s()' % func.func_name
        self.log.debug('Running %s' % transition)
        if self.state != begin_state:
            raise RuntimeError(
                'Unexpected state %r: Cannot %s unless in state %r' %
                (self.state, begin_state, transition))
        try:
            func()
        except Exception, e:
            self.log.warning('Failed %s (%s) - cleaning up' % (transition, e))
            self.cleanup()
            raise
        else:
            self.state = end_state

    def _setup_loggers_and_handlers(self):
        """
        Simple wrapper function to call the setups for loggers and handlers
        """
        self.__transition(self._setup_loggers, self.CLEAN, self.DETACHED)
        self.__transition(self._setup_handlers, self.DETACHED, self.DETACHED)

    def _setup_loggers(self):
        """
        Create the loggers that are owned by this LogGroup.
        This should be idempotent
        """
        self.root_logger = setup_logging(None)  # name=None indicates root

    def _setup_handlers(self):
        """
        Create the handlers that are used by this LogGroup.
        The default is a single debug-level logfile.
        Note: any LogGroup will use the global stream handler when attached.
        """
        self.debug_handler = self._setup_handler(
            default_handler, self.root_logger, filename=self.debug_logfile)

    def _setup_handler(self, handling, log, filename=None, level=DEBUG,
                       attached=False):
        """
        Adds a new handler to the LogGroup.
            handling - Function such as default_handler, simple_handler, ...
            log - Log as returned by logging.getLogger
            filename - Filename to associate the handler with
            level - Log level to limit the handler to
            attached - Should be False unless the handler we get by calling
                       handling is already attached.  Do not usually set this.
        """
        handler = handling(filename=filename, level=level)
        attached = False
        self._log_handlers.append([log, handler, attached])
        return handler

    def attach(self):
        """
        Attaches all handlers to their logs.
        Transitions from DETACHED to ATTACHED state.
        """
        self.__transition(self.__attach, self.DETACHED, self.ATTACHED)

    def __attach(self):
        """
        Actual function used to perform attachment.
        """
        # TODO: Unique checks should not be necessary with proper invocation,
        # but are still useful for doctest logger, and have little overhead.
        for info in self._log_handlers:
            log, handler, attached = info
            if not attached:
                _add_unique_handler(log, handler)
                info[2] = True  # Mark as attached
        # Deliberately last to avoid symlinking in failure cases
        self.__update_link(self.default_latest_logfile, self.linked_logfile)
        if self.latest_logfile != self.default_latest_logfile:
            self.__update_link(self.latest_logfile, self.linked_logfile)

    def __update_link(self, link_path, target_path):
        """
        Attempts to create a link at link_path pointing towards target_path.
        If a symlink already exists at link_path, we replace it.  Normal
        files in that location will cause a warning, and we will continue.

        Returns True if the link was created or updated, False otherwise.
        """
        self.log.info('Symlinking %r -> %r' % (link_path, target_path))
        success = False
        try:
            os.symlink(target_path, link_path)
        except OSError as e:
            if e.errno == errno.EEXIST and os.path.islink(link_path):
                self.log.debug('Replacing old link at %r' % link_path)
                try:
                    os.remove(link_path)
                    os.symlink(target_path, link_path)
                except OSError as e:
                    self.log.warn('Unable to replace symlink: %r' % e)
                else:
                    success = True
            else:
                self.log.warn('Unable to create symlink: %r' % e)
        else:
            success = True
        if success:
            os.chmod(link_path, 0777)  # Ensure everyone can replace link
        return success

    def detach(self):
        """
        Detaches all handlers from their logs.
        Transitions from ATTACHED to DETACHED state.
        """
        self.__transition(self.__detach, self.ATTACHED, self.DETACHED)

    def __detach(self):
        """
        Actual function used to perform detachment.
        """
        # Note that we don't attempt to create/use a remove_unique_handler
        for info in self._log_handlers:
            log, handler, attached = info
            if attached:
                log.removeHandler(handler)
                info[2] = False

    def cleanup(self):
        """
        Attempts to clean up the LogGroup, detaching any attached handlers,
        and wiping variables.
        """
        self.log.debug('Cleaning up')
        try:
            if self.state == self.ATTACHED:
                self.detach()
            self._reset()
        except Exception:
            self.state = self.DIRTY
            raise

    def __del__(self):
        """
        We don't expect to fall out of scope during normal operation, but it
        is expected to happen at the end of every execution.
        """
        msg = 'Logger %s fell out of scope' % self
        try:
            self.log.debug(msg)
        except Exception:
            pass  # If the log is already gone (process exit) we don't care
        try:
            self.cleanup()  # Do generic cleanup if possible
        except Exception:
            pass


class TestLogGroup(LogGroup):

    """
    When setup() is run, the following files would be created

    The default directory is configurable by the global variable test_log_dir
    The default filename is 'qe'.

        <BASEDIR>.<BASEPATH>.latest.log
            - Symlink to INFO+ log (rewritten any time setup/attach is called)

        <BASEDIR>.<BASEPATH>.<TIMESTAMP>.log
            - INFO+ level of non-RAW logs

        <BASEDIR>.<BASEPATH>.<TIMESTAMP>.DEBUG.log
            - DEBUG+ level of non-RAW logs

        <BASEDIR>.<BASEPATH>.<TIMESTAMP>.RAW.log
            - special RAW log that stores exact commands (ssh/api/pexpect/etc)

        <BASEDIR>.<BASEPATH>.<TIMESTAMP>.RUN.log
            - special RUN log for meta info related to high level test progress
    """

    def __get_base_dir(self):
        # Support for DEPRECATED global variable
        global test_log_dir
        return test_log_dir

    def __set_base_dir(self, value):
        # Support for DEPRECATED global variable
        global test_log_dir
        test_log_dir = value

    DEFAULT_BASE_DIR = property(fget=__get_base_dir, fset=__set_base_dir)
    DEFAULT_BASE_FILE = 'qe'

    def _prepare_filenames(self):
        """
        Must be called once, and only during __init__
        'Logfiles' are just a string representation of path
        """
        super(TestLogGroup, self)._prepare_filenames()
        self.info_logfile = "%s.log" % self._logfile_prefix
        self.raw_logfile = "%s.RAW.log" % self._logfile_prefix
        self.run_logfile = "%s.RUN.log" % self._logfile_prefix
        # Designates the file to link 'recent' to
        self.linked_logfile = self.info_logfile

    def _reset(self):
        """
        Helper function to reset all variables to an initial state.
        Does not attempt to do any of the cleaning associated with this.
        """
        super(TestLogGroup, self)._reset()
        # Loggers
        self.run_logger = None
        # Handlers
        self.info_handler = None
        self.raw_handler = None
        self.run_handler = None

    def _setup_loggers(self):
        """
        Simple wrapper function to call the setups for loggers and handlers
        """
        super(TestLogGroup, self)._setup_loggers()
        # Explicitly handle outside of root, since we use a different
        self.raw_logger = setup_logging(name=_raw_name, propagate=False)
        self.run_logger = setup_logging(name='run', propagate=False)

    def _setup_handlers(self):
        """
        Create the handlers that are used by this LogGroup.
        The default is a single debug-level logfile.
        Note: any LogGroup will use the global stream handler when attached.
        """
        super(TestLogGroup, self)._setup_handlers()
        self.info_handler = self._setup_handler(
            default_handler, self.root_logger, filename=self.info_logfile,
            level=INFO)
        self.raw_handler = self._setup_handler(
            raw_handler, self.raw_logger, filename=self.raw_logfile)
        self.run_handler = self._setup_handler(
            run_handler, self.run_logger, filename=self.run_logfile)
        self.root_debug_run_handler = self._setup_handler(
            run_handler, self.run_logger, filename=self.debug_logfile)
        self.root_info_run_handler = self._setup_handler(
            run_handler, self.run_logger, filename=self.info_logfile,
            level=INFO)
        self.stream_run_handler = self._setup_handler(
            run_handler, self.run_logger)


def log_raw(msg):
    """
    Delegate a raw logging call to the base raw_logger
    """
    global raw_logger
    raw_logger.info(msg)


# This is deliberately done at import-time
__initialize_logger()
