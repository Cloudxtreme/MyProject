import vmware.base.appmgmt as appmgmt
import vmware.nsx.manager.manager_client as manager_client


class InterfaceCLIClient(appmgmt.ApplianceManagement,
                         manager_client.NSXManagerCLIClient):

    """
    Please don't copy paste, we have to create separate classes
    for each client.
    """

    def __init__(self, parent=None, id_=None):
        super(InterfaceCLIClient, self).__init__(parent=parent)
        self.id_ = id_