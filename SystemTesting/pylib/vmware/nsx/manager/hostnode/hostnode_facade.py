import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.hostnode.api.hostnode_api_client as \
    hostnode_api_client
import vmware.nsx.manager.hostnode.hostnode as host_node

pylogger = global_config.pylogger


class HostNodeFacade(host_node.HostNode, base_facade.BaseFacade):

    """ Host Node facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(HostNodeFacade, self).__init__(parent=parent, id_=id_)

        # Instantiate client objects
        api_client = hostnode_api_client.HostNodeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)

        # Maintain the list of client objects
        self._clients = {constants.ExecutionType.API: api_client}
