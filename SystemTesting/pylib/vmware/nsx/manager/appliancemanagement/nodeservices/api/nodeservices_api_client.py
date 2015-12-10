import vmware.base.appmgmt as appmgmt
import vmware.nsx.manager.manager_client as manager_client


class NodeServicesAPIClient(appmgmt.ApplianceManagement,
                            manager_client.NSXManagerAPIClient):

    """
    NodeServicesAPIClient to perform CRUDQ on NSX services.
    """

    def __init__(self, parent=None, id_=None):
        super(NodeServicesAPIClient, self).__init__(parent=parent)
        self.id_ = id_