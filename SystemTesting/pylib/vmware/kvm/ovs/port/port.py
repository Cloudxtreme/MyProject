import ovsdb.ovsdb as ovsdb
import vmware.base.port as port


class Port(port.Port):
    DB_CLIENT = 'ovsdb-client'
    VSCTL = 'ovs-vsctl'

    def __init__(self, name=None, parent=None, **kwargs):
        self.parent = parent
        self.name = name
        self.ovsdb = ovsdb.OVSDB(self)

    def req_call(self, cmd, **kwargs):
        return self.connection.request(cmd).response_data

    @property
    def bridge_name(self):
        return self.parent.name

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION
