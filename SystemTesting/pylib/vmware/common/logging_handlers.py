import logging
import racetrack

import vmware.common.global_config as global_config


pylogger = global_config.pylogger


class EqualityMixin(object):
    """Mixin for comparison operation support."""

    def __eq__(self, other):
        return (isinstance(other, self.__class__) and
                other.__dict__ == self.__dict__)

    def __ne__(self, other):
        return not self.__eq__(other)


class LoggerPluginMixin(object):
    """Mixin for custom logging handlers."""

    def attach(self, logger):
        """
        Attach this logging handler to logger after first removing any similar
        logging handlers.

        @type logger: logging.Logger instance
        @param logger: Logger to which this handler will be attached.
        """
        try:
            self.detach(logger)
        except ValueError:
            # suppress exception for no handler
            pass
        logger.addHandler(self)

    def detach(self, logger):
        """
        Detach this logging handler from logger. Raise exception if no
        handlers were found that are similar to this handler instance.
        """
        existing_handlers = [h for h in logger.handlers if self == h]
        if not existing_handlers:
            raise ValueError("Handler not found on logger: %s: %s" %
                             (logger, self))
        for h in existing_handlers:
            pylogger.debug("Removing handler from logger: %s: %s" %
                           (logger, h))
            logger.removeHandler(h)


class RacetrackLoggingHandler(LoggerPluginMixin, EqualityMixin,
                              logging.Handler):
    """
    Logging Handler for commenting to Racetrack.

    @type config_handle: reporter.Reporter configuration handle
    @param config_handle: Configuration information to initialize Reporter
        instance.

    Name of the Racetrack logging hander is synthesized from the test case
    or set ID, with priority to test case.
    >>> RacetrackLoggingHandler(dict(
    ...     _reportType="Racetrack",
    ...     server="http://racetrack-dev.eng.vmware.com",
    ...     user="jschmidt",
    ...     testSetId="673672",
    ...     testCaseId="11521647")).name
    'Racetrack-11521647'
    >>> RacetrackLoggingHandler(dict(
    ...     _reportType="Racetrack",
    ...     server="http://racetrack-dev.eng.vmware.com",
    ...     user="jschmidt",
    ...     testSetId="673672",
    ...     testCaseId=None)).name
    'Racetrack-673672'
    """

    def __init__(self, config_handle, **kwargs):
        # XXX(jschmidt): Structure of config_handle is loosely bound,
        # formalize it.
        self._config_handle = config_handle
        if not self._config_handle['_reportType'] == 'Racetrack':
            raise ValueError("Can not create logging handler, reporting "
                             "configuration is not for Racetrack: %r" %
                             config_handle)
        if not (self._config_handle['testSetId'] or
                self._config_handle['testCaseId']):
            raise ValueError("Logging handler for Racetrack requires a test "
                             "set or case ID, got neither")
        super(RacetrackLoggingHandler, self).__init__(**kwargs)
        # Limit message commenting to Racetrack to INFO level, no DEBUG.
        self.setLevel(logging.INFO)
        if not self.name:
            id_ = (self._config_handle['testCaseId'] or
                   self._config_handle['testSetId'])
            self.name = ("%s-%s" % (self._config_handle['_reportType'], id_))

    def __eq__(self, other):
        if not isinstance(other, self.__class__):
            return False
        if not hasattr(other, '_config_handle'):
            return False
        # Racetrack logging handler is similar if targeting the same server
        # and test set. User can be different. Test case ID is allowed to vary
        # and be considered as the same handler. This allows for updating the
        # logging handler when new test cases from the same set are started.
        attrs = ('server', 'testSetId')
        return all(self._config_handle[a] == other._config_handle.get(a)
                   for a in attrs)

    def emit(self, record):
        desc = "[%s] - %s" % (record.levelname, record.message)
        # Racetrack lifecycle is handled within VDNet core using Racetrack
        # Perl package. As the Python racetrack module is not updated with
        # test state, patch the module's global attrs with current state
        # understanding that was stored to the internal _config_handle.
        map_config_handle_to_racetrack = {
            'server': 'server',
            'user': 'user',
            'testSetId': 'testSetID',
            'testCaseId': 'testCaseID'}
        for k, v in map_config_handle_to_racetrack.iteritems():
            setattr(racetrack, v, self._config_handle[k])
        racetrack.comment(desc)


if __name__ == "__main__":
    import doctest
    doctest.testmod(optionflags=(
        doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE))
