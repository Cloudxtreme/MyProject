import vmware.base.ipfix as ipfix
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.ipfix.api.ipfix_api_client as ipfix_api_client
import vmware.nsx.manager.ipfix.cli.ipfix_cli_client as ipfix_cli_client


pylogger = global_config.pylogger


class IpfixFacade(ipfix.Ipfix, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(IpfixFacade, self).__init__(parent=parent, id_=id_)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = ipfix_api_client.IpfixAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = ipfix_cli_client.IpfixCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
