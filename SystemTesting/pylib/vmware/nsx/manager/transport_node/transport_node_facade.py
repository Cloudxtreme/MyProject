import vmware.base.node as node
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.transport_node.api.transport_node_api_client\
    as transport_node_api_client
import vmware.nsx.manager.transport_node.cli.transport_node_cli_client\
    as transport_node_cli_client


pylogger = global_config.pylogger


class TransportNodeFacade(node.Node, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(TransportNodeFacade, self).__init__(parent=parent, id_=id_)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = transport_node_api_client.TransportNodeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = transport_node_cli_client.TransportNodeCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
