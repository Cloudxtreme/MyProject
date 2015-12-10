import racetrack

import vmware.common.global_config as global_config
import vmware.common.logging_handlers as logging_handlers


pylogger = global_config.pylogger


class Reporter(object):
    """
    Status reporting for testing tasks.

    @type config_handle: object
    @param config_handle: Class-specific object to initialize Reporter
        instance.
    """

    _REPORTER_TYPE = None

    def __init__(self, config_handle, **kwargs):
        # TODO(jschmidt, llai, gjayavelu): VDNet core framework will later
        # make direct use of pylib.common.racetrack instead of Perl Racetrack
        # module. The code in Reporter and related classes that threads through
        # Racetrack configuration in this config_handle can be removed and
        # instead rely on core framework to appropriately set the Racetrack
        # configuration.
        self._config_handle = config_handle

    def _get_logging_handler(self):
        """Return a logging handler appropriate for this Reporter instance."""
        return None

    def step_pass(self, msg=None, **kwargs):
        raise NotImplementedError("Sub-class implementation required")

    def step_fail(self, msg=None, **kwargs):
        raise NotImplementedError("Sub-class implementation required")

    def step_report(self, result=None, **kwargs):
        """
        Report test step result.

        @type result: boolean
        @param result: True if the test step passed expectation, otherwise
            False.
        """
        if result is None:
            raise ValueError("result is required, None given")
        if type(result) != bool:
            raise ValueError("result must be type 'bool', got: %s: %r" %
                             (type(result), result))
        reporting_func = self.step_pass if result else self.step_fail
        return reporting_func(**kwargs)


class RacetrackReporter(Reporter):
    """
    Status reporting to Racetrack for testing tasks.
    """

    _REPORTER_TYPE = "Racetrack"

    def __init__(self, config_handle, **kwargs):
        # following settings correspond to attrs of racetrack module
        self._config_handle = config_handle
        super(RacetrackReporter, self).__init__(config_handle, **kwargs)

    def _rt_patch_globals(self):
        # TODO(jschmidt): Mapping between config_handle keys and racetrack
        # module attributes is fragile coupling. Longer term vision is that
        # VDNet core framework takes care to properly configure
        # pylib.common.racetrack. This fragile way of threading Racetrack
        # configuration across framework layers and patching module globals
        # could be removed.
        _RT_GLOBALS = {
            # <config_handle field>: <racetrack module field>
            "server": "server",
            "user": "user",
            "testSetId": "testSetID",
            "testCaseId": "testCaseID",
        }
        for k, v in _RT_GLOBALS.iteritems():
            setattr(racetrack, v, self._config_handle.get(k))

    def _rt_step_report(self, msg=None, actual=None, expected=None,
                        result=None):
        self._rt_patch_globals()
        racetrack.testCaseVerification(msg, actual, expected, Result=result,
                                       Screenshot=None)

    def step_pass(self, msg=None, **kwargs):
        return self._rt_step_report(result='TRUE', msg=msg, **kwargs)

    def step_fail(self, msg=None, **kwargs):
        return self._rt_step_report(result='FALSE', msg=msg, **kwargs)

    def _get_logging_handler(self):
        """Return a logging handler that comments to Racetrack."""
        return logging_handlers.RacetrackLoggingHandler(self._config_handle)


class ReporterFactory(object):
    """
    Create a Reporter instance of specific type.
    """

    _TYPE_RT = 'Racetrack'
    # Map supported types to target class.
    _SUPPORTED_TYPES = {
        _TYPE_RT: RacetrackReporter
    }

    @staticmethod
    def get_reporter(config_handle):
        """
        Factory method to create Reporter instances.

        @type config_handle: dict
        @param config_handle: A dictionary description of a handle to a
            reporting system. Only the '_reportType' key is guaranteed,
            and explains the type of handle provided. Additional data is
            dependent on the type of Reporter invoked and is passed as
            constructor parameter to the final Reporter.
        """
        # TODO(jschmidt): The 'type' of the config_handle is loose with initial
        # provisions using a plain dictionary. Formalize the type handling for
        # config_handle. Be cautious that the same data is likely created in
        # other-language modules of VDNet, and formalization should include
        # all usage areas not limited to this module.
        if type(config_handle) != dict:
            raise ValueError("config_handle must be a dictionary, got: %r: %r"
                             % (type(config_handle), config_handle))
        type_ = config_handle.get('_reportType')
        if type_ not in ReporterFactory._SUPPORTED_TYPES:
            raise ValueError("Reporting type not supported: %s" % type_)
        rptr = ReporterFactory._SUPPORTED_TYPES[type_](config_handle)
        return rptr


def configure_pylogger_reporter(config_handle):
    """Set the test reporting handle on the global pylogger."""
    global pylogger
    if getattr(pylogger, "_reporter_config", None):
        pylogger.debug("Removing Reporter config from global pylogger:\n%r" %
                       pylogger._reporter_config)
    pylogger.debug("Adding Reporter config to global pylogger:\n%r" %
                   config_handle)
    pylogger._reporter_config = config_handle
    rptr = ReporterFactory.get_reporter(config_handle)
    logging_handler = rptr._get_logging_handler()
    if logging_handler:
        pylogger.debug("Attaching logging handler to global pylogger: %s" %
                       type(logging_handler))
        logging_handler.attach(pylogger)
    else:
        pylogger.debug("No logging handler available for Reporter: %s" %
                       type(rptr))
