import vmware.common.base_facade as base_facade
import vmware.common.constants as constants

import vmware.nsx.edge.edge_node.edge_node as edge_node
import vmware.nsx.edge.edge_node.api.edge_node_api_client \
    as edge_node_api_client
import vmware.nsx.edge.edge_node.cli.edge_node_cli_client \
    as edge_node_cli_client


class EdgeNodeFacade(edge_node.EdgeNode, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(EdgeNodeFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent
        self.id_ = id_

        # instantiate client objects
        api_client = edge_node_api_client.EdgeNodeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = edge_node_cli_client.EdgeNodeCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}