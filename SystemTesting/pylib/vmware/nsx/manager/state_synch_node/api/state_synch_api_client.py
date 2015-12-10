import vmware.base.node as node
import vmware.nsx.manager.api.manager_api_client as manager_api_client


class StateSynchNodeAPIClient(node.Node, manager_api_client.ManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(StateSynchNodeAPIClient, self).__init__(parent=parent)
        self.id_ = id_
