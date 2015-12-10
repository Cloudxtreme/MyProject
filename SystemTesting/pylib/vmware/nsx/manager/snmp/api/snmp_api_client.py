import vmware.base.snmp as snmp
import vmware.nsx.manager.manager_client as manager_client


class SnmpAPIClient(snmp.SnmpManager,
                    manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(SnmpAPIClient, self).__init__(parent=parent)
        self.id_ = id_