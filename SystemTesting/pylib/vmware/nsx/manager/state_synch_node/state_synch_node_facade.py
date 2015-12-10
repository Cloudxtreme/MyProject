import vmware.base.node as node
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.state_synch_node.api.state_synch_api_client as\
    state_synch_api_client

pylogger = global_config.pylogger


class StateSynchNodeFacade(node.Node, base_facade.BaseFacade):
    """State Synch Node facade class to perform CRUDAQ"""
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(StateSynchNodeFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent
        self.id_ = id_

        api_client = state_synch_api_client.StateSynchNodeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        self._clients = {constants.ExecutionType.API: api_client}
