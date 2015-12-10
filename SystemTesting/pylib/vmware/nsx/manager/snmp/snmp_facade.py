import vmware.base.snmp as snmp
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.snmp.api.snmp_api_client as snmp_api_client
import vmware.nsx.manager.snmp.cli.snmp_cli_client as snmp_cli_client


pylogger = global_config.pylogger


class SnmpFacade(snmp.SnmpManager, base_facade.BaseFacade):
    """ SNMP Facade
    """
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(SnmpFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = snmp_api_client.SnmpAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = snmp_cli_client.SnmpCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}