import vmware.base.appmgmt as appmgmt
import vmware.nsx.manager.manager_client as manager_client


class RouteAPIClient(appmgmt.ApplianceManagement,
                     manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(RouteAPIClient, self).__init__(parent=parent)
        self.id_ = id_
