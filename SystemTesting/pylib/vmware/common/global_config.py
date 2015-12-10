import errno
import logging
import logging.handlers as handlers
import os
import getpass
import sys
import tempfile

USER = getpass.getuser()
DEFAULT_USER_DIR = os.path.join(tempfile.gettempdir(), USER)
try:
    os.mkdir(DEFAULT_USER_DIR)
except OSError, e:
    if e.errno != errno.EEXIST:
        raise
DEFAULT_LOG_DIR = tempfile.mkdtemp(dir=DEFAULT_USER_DIR, prefix="vdnet_")
DEFAULT_LOG_FORMATTER = logging.Formatter(
    '%(asctime)s %(levelname)-8s %(filename)s:%(lineno)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S')
DEFAULT_STDOUT_FORMATTER = logging.Formatter(
    '%(asctime)s %(levelname)-8s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S')
DEFAULT_LOG_LEVEL = logging.INFO
DEFAULT_LOGFILE_LEVEL = logging.DEBUG
DEFAULT_LOG_PREFIX = 'pylib'
DEFAULT_LOG_STDOUT = True

# MPA
DEFAULT_MPA_CONFIG = '/etc/vmware/nsx-mpa/mpaconfig.json'
SAMPLE_CLIENT_LOCATION = '/tmp/'
DEFAULT_SAMPLE_CLIENT_START_SEQUENCE = 'chmod +x %ssample_client; ' % \
    SAMPLE_CLIENT_LOCATION + \
    'LD_LIBRARY_PATH=/usr/lib64/vmware/nsx-mpa %ssample_client' % \
    SAMPLE_CLIENT_LOCATION
DEFAULT_PASSWORD = 'ca$hc0w'
DEFAULT_ESX_PROTOBUF_PATH = '/usr/lib/vmware/nsx-common/lib/python/'
DEFAULT_KVM_RMQLIB_PATH = '/usr/lib64/vmware/nsx-mpa/librmqclient64.so'
DEFAULT_ESX_RMQLIB_PATH = '/usr/lib/vmware/nsx-mpa/librmqclient.so'
SAMPLE_CLIENT_COOKIEID_FILE = '/tmp/cookieid.txt'  # TODO - Autogenerate?
MSG_TYPE_GENERIC = 1
MSG_TYPE_RPC = 2
MSG_TYPE_PUBLISH = 3

# Flags to enable/disable debug logging that are chatty
ENABLE_DEBUG_RESOLVE = False

pylogger = None

COMMAND_EXEC_TIMEOUT = 120  # Seconds
PACKAGE_INSTALL_TIMEOUT = 300  # Seconds


def configure_logger(log_dir=None, log_prefix=None, log_level=None,
                     logfile_level=None, logger_name=None,
                     formatter=None, stdout=None, maxBytes=0, backupCount=0):
    """
    Configures and returns a logger object with correct loglevels for stdout
    and file handlers as directed by the params

    @type log_dir: str
    @param log_dir: Directory where log file is to be created
    @type log_prefix: str
    @param log_prefix: Prefix for log file which is always suffixed with .log
    @type log_level: str
    @param log_level: Minimum log level for logging messages to stdout
    @type logfile_level: str
    @param logfile_level: Minimum log level for logging messages to file
    @type logger_name: str
    @param logger_name: Name of the logger to acquire. If "root" is provided
        then the parent of all the logger is setup by this method.
    @type formatter: logging.Formatter
    @param formatter: Formatter that specifies the layout and format of the
        log messages
    @type stdout: bool
    @param stdout: Flag to enable or disable output to stdout
    @type maxBytes: int
    @param maxBytes: Max size in bytes for the file to be rotated,
        0 means unlimited and never rotated
    @type backupCount: int
    @param backupCount: Max number of files to be rotated, 0 means single file
    """
    if log_dir is None:
        log_dir = DEFAULT_LOG_DIR
    if log_prefix is None:
        log_prefix = DEFAULT_LOG_PREFIX
    if logger_name is None:
        logger_name = log_prefix
    if log_level is None:
        log_level = DEFAULT_LOG_LEVEL
    if logfile_level is None:
        logfile_level = DEFAULT_LOGFILE_LEVEL
    if formatter is None:
        formatter = DEFAULT_STDOUT_FORMATTER
    if stdout is None:
        stdout = DEFAULT_LOG_STDOUT

    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    logfile = "%s.log" % os.sep.join([log_dir, log_prefix])
    if logger_name.lower() == "root":
        # Returns root logger that is the common ancestor of all loggers.
        logger = logging.getLogger()
    else:
        logger = logging.getLogger(logger_name)
    logger.propagate = False

    fh = handlers.RotatingFileHandler(
        logfile, maxBytes=maxBytes, backupCount=backupCount)
    fh.setLevel(logfile_level)
    fh.setFormatter(DEFAULT_LOG_FORMATTER)
    logger.addHandler(fh)

    # Remove old file and stream handlers if configure_logger is called
    # multiple times for the same logger else it will create duplicate logging
    for fh in logger.handlers:
        if hasattr(fh, 'baseFilename'):
            if logfile not in fh.baseFilename:
                logger.removeHandler(fh)
        else:  # remove old stream handler to stdout
            logger.removeHandler(fh)

    # set stream handler for stdout
    if stdout:
        sh = logging.StreamHandler(sys.stdout)
        sh.setLevel(log_level)
        sh.setFormatter(formatter)
        logger.addHandler(sh)

    return logger


def configure_global_pylogger(*args, **kwargs):
    # Ensuring that mh lib root logger initialization is done before we
    # overwrite all handlers here. Since the root logger is at the base of
    # logger hierarchy and we are overwriting the handlers in our config, all
    # the mh modules will be using our handlers from now on.
    import lib.logger as logger
    _ = logger  # Suppress pychecker warning.
    global pylogger
    logging.basicConfig(level=DEFAULT_LOG_LEVEL)
    pylogger = configure_logger(*args, **kwargs)
    return pylogger


def get_base_log_file():
    """ Returns log file used by the logger """
    for fh in pylogger.handlers:
        if hasattr(fh, 'baseFilename'):
            return fh.baseFilename
    raise ValueError("No base log file configured")


def get_base_log_dir():
    """ Returns base log directory used by the logger """
    base_log_file = get_base_log_file()
    return os.path.dirname(base_log_file)


def get_host_keys_file():
    """ Get ssh_known_hosts file in the base log directory """
    path = os.path.join(get_base_log_dir(), "ssh_known_hosts")
    with open(path, 'a'):
        os.utime(path, None)
    return path

try:
    configure_global_pylogger()
except Exception, error:
    print "[WARN]  - Default logger not enabled %s" % error
