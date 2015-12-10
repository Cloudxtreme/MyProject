import vmware.base.logserver as logserver
import vmware.nsx.manager.manager_client as manager_client


class SyslogServerAPIClient(logserver.Logserver, manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(SyslogServerAPIClient, self).__init__(parent=parent)
        self.id_ = id_

