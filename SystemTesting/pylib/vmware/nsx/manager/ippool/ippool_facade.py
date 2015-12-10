import vmware.nsx.manager.ippool.ippool as ippool
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.ippool.api.ippool_api_client as ippool_api_client
import vmware.nsx.manager.ippool.cli.ippool_cli_client as ippool_cli_client

pylogger = global_config.pylogger


class IPPoolFacade(ippool.IPPool, base_facade.BaseFacade):
    """IPPool facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(IPPoolFacade, self).__init__(parent)
        self.nsx_manager_obj = parent
        self.id_ = id_

        # instantiate client objects
        api_client = ippool_api_client.IPPoolAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = ippool_cli_client.IPPoolCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
