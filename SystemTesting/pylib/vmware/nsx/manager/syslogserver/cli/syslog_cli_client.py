import vmware.base.logserver as logserver
import vmware.nsx.manager.manager_client as manager_client


class SyslogServerCLIClient(logserver.Logserver, manager_client.NSXManagerCLIClient):

    def __init__(self, parent=None, id_=None):
        super(SyslogServerCLIClient, self).__init__(parent=parent)
        self.id_ = id_

