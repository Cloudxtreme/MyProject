import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.nodeservices.api.\
    nodeservices_api_client as nodeservices_api_client
import vmware.nsx.manager.appliancemanagement.nodeservices.cli.\
    nodeservices_cli_client as nodeservices_cli_client

pylogger = global_config.pylogger


class NodeServicesFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """NodeServices facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(NodeServicesFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = nodeservices_api_client.NodeServicesAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=None)
        cli_client = nodeservices_cli_client.NodeServicesCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
