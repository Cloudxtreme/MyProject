import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class SnmpManager(base.Base):
    # This is a base class for
    # SNMP manager which will
    # fetch MIBs from NSX MP node

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(SnmpManager, self).__init__()
        self.parent = parent

    @auto_resolve(labels.SNMP)
    def get_system_mib(self, execution_type=None,
                       manager_ip=None, **kwargs):
        """
        Fetch system MIBs from NSX MP node.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.SNMP)
    def get_interfaces_mib(self, execution_type=None,
                           manager_ip=None, **kwargs):
        """
        Fetch interfaces MIBs from NSX MP node.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.SNMP)
    def get_hostresources_mib(self, execution_type=None,
                              manager_ip=None, **kwargs):
        """
        Fetch host resources MIBs from NSX MP node.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass