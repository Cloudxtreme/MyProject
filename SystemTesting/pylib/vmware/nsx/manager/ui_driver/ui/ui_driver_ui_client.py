import vmware.base.driver as driver
import vmware.nsx.manager.manager_client as manager_client


class UIDriverUIClient(driver.Driver, manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(UIDriverUIClient, self).__init__(parent=parent)
        self.id_ = id_
