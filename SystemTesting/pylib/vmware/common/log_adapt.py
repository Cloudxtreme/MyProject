#!/usr/bin/env python

ALLOW_LOGGING_MODULE = True  # See style_checker

import logging


def _get_name(name, extra):
    key = 'source'
    sep = '::'
    if key in extra:
        source = extra[key]
        # extra['source'] should end with sep, move to beginning so name
        # looks like <logger>::<source> instead of <logger><source>::
        if source.endswith(sep):
            source = '%s%s' % (sep, source[:-len(sep)])
        name += source
    return name


class _LoggerAdapter:
    """
    An adapter for loggers which makes it easier to specify contextual
    information in logging output.
    """

    def __init__(self, logger, extra):
        """
        Initialize the adapter with a logger and a dict-like object which
        provides contextual information. This constructor signature allows
        easy stacking of LoggerAdapters, if so desired.

        You can effectively pass keyword arguments as shown in the
        following example:

        adapter = LoggerAdapter(someLogger, dict(p1=v1, p2="v2"))
        """
        self.logger = logger
        self.name = _get_name(logger.name, extra)
        self.level = self.logger.level
        self.extra = extra

    def process(self, msg, kwargs):
        """
        Process the logging message and keyword arguments passed in to
        a logging call to insert contextual information. You can either
        manipulate the message itself, the keyword args or both. Return
        the message and kwargs modified (or not) to suit your needs.

        Normally, you'll only need to override this one method in a
        LoggerAdapter subclass for your specific needs.
        """
        kwargs["extra"] = self.extra
        return msg, kwargs

    def debug(self, msg, *args, **kwargs):
        """
        Delegate a debug call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        self.logger.debug(msg, *args, **kwargs)

    def info(self, msg, *args, **kwargs):
        """
        Delegate an info call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        self.logger.info(msg, *args, **kwargs)

    def warning(self, msg, *args, **kwargs):
        """
        Delegate a warning call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        self.logger.warning(msg, *args, **kwargs)
    warn = warning

    def error(self, msg, *args, **kwargs):
        """
        Delegate an error call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        self.logger.error(msg, *args, **kwargs)

    def exception(self, msg, *args, **kwargs):
        """
        Delegate an exception call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        kwargs["exc_info"] = 1
        self.logger.error(msg, *args, **kwargs)

    def critical(self, msg, *args, **kwargs):
        """
        Delegate a critical call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        self.logger.critical(msg, *args, **kwargs)

    def log(self, level, msg, *args, **kwargs):
        """
        Delegate a log call to the underlying logger, after adding
        contextual information from this adapter instance.
        """
        msg, kwargs = self.process(msg, kwargs)
        self.logger.log(level, msg, *args, **kwargs)

    def setLevel(self, level):
        self.logger.setLevel(level)
        self.level = level


# Python did not add a built-in LoggerAdapter until 2.7, we attempt to use the
# built-in when it is available, along with modifications to setLevel and to
# expose the name and level variables.
try:
    class _LoggerAdapter(logging.LoggerAdapter):
        def setLevel(self, level):
            # For some reason built-in adapters didn't get setLevel
            self.logger.setLevel(level)
            self.level = level

        def __init__(self, *a, **kw):
            # We want to expose the name and level on the adapter
            logging.LoggerAdapter.__init__(self, *a, **kw)
            self.name = _get_name(self.logger.name, self.extra)
            self.level = self.logger.level

        warn = logging.LoggerAdapter.warning
except (ImportError, AttributeError):
    pass
LoggerAdapter = _LoggerAdapter
