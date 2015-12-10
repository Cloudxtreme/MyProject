import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class Network(base.Base):

    def __init__(self, name=None, parent=None):
        super(Network, self).__init__()
        self.name = name
        self.parent = parent

    @auto_resolve(labels.CRUD)
    def update(self, execution_type=None, **kwargs):
        """Update the network."""
        pass

    @auto_resolve(labels.CRUD)
    def read(self, execution_type=None, **kwargs):
        """Reads the properties of the network."""
        pass

    @auto_resolve(labels.NETWORK)
    def edit_traffic_shaping(self, execution_type=None, **kwargs):
        """Edits traffic shaping policy."""
        pass

    @auto_resolve(labels.ADAPTER)
    def add_virtual_interface(self, execution_type=None, **kwargs):
        """Adds a virtual interface to the network."""
        pass

    @auto_resolve(labels.NETWORK)
    def edit_security_policy(self, execution_type=None, **kwargs):
        """Edits the security policy on the network."""
        pass

    @auto_resolve(labels.NETWORK)
    def set_access_vlan(self, execution_type=None, vlan=None, **kwargs):
        """Sets an access vlan on the network."""
        pass

    @auto_resolve(labels.NETWORK)
    def set_vlan_trunking(self, execution_type=None, **kwargs):
        """Sets vlan trunking on the network."""
        pass

    @auto_resolve(labels.SWITCH)
    def set_nic_teaming(self, execution_type=None, **kwargs):
        """Sets nic teaming on the switch."""
        pass

    @auto_resolve(labels.NETWORK)
    def migrate_network(self, execution_type=None,
                                   hostname=None, **kwargs):
        """Migrates the network."""
        pass

    @auto_resolve(labels.CRUD)
    def create(self, execution_type=None, **kwargs):
        """Creates a network"""
        pass
