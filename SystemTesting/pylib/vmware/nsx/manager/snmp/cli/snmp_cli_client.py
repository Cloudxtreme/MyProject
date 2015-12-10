import vmware.base.snmp as snmp
import vmware.nsx.manager.manager_client as manager_client


class SnmpCLIClient(snmp.SnmpManager,
                    manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(SnmpCLIClient, self).__init__(parent=parent)
        self.id_ = id_