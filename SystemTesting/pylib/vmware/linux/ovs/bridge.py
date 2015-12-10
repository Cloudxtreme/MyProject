import ovsdb.ovsdb as ovsdb
import vmware.base.switch as switch
import vmware.common.constants as constants
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

CLI = constants.ExecutionType.CLI


class Bridge(switch.Switch):
    DEFAULT_EXECUTION_TYPE = CLI
    DEFAULT_IMPLEMENTATION_VERSION = 'Default'
    DB_CLIENT = 'ovsdb-client'
    VSCTL = 'ovs-vsctl'

    def __init__(self, name=None, parent=None, **kwargs):
        super(Bridge, self).__init__(parent=parent)
        self.name = name
        self.ovsdb = ovsdb.OVSDB(self)

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def req_call(self, cmd, **kwargs):
        return self.connection.request(cmd).response_data

    @base_facade.auto_resolve(labels.SWITCH)
    def set_port_mtu(self, execution_type=None, **kwargs):
        pass
