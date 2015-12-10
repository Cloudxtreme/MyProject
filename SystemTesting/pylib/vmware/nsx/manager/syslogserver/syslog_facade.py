__author__ = 'aghaisas'

import vmware.base.logserver as logserver
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.syslogserver.api.syslog_api_client as syslog_api_client
import vmware.nsx.manager.syslogserver.cli.syslog_cli_client as syslog_cli_client


pylogger = global_config.pylogger


class SyslogFacade(logserver.Logserver, base_facade.BaseFacade):
    """ Syslog server Facade
    """
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(SyslogFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = syslog_api_client.SyslogServerAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = syslog_cli_client.SyslogServerCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}