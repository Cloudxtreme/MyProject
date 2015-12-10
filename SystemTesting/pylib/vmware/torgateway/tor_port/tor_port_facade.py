import vmware.torgateway.tor_port.tor_port as tor_port
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels
import vmware.torgateway.tor_port.cmd.tor_port_cmd_client as \
    tor_port_cmd_client

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class TORPortFacade(tor_port.TORPort, base_facade.BaseFacade):
    """TOR Switch facade class"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CMD

    def __init__(self, parent=None, name=None):
        super(TORPortFacade, self).__init__(parent=parent, name=name)
        self.parent = parent
        pylogger.debug('Name of port: %s' % name)
        self.name = name

        # instantiate client objects.
        cmd_client = tor_port_cmd_client.TORPortCMDClient(
            parent=parent.get_client(constants.ExecutionType.CMD), name=name)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.CMD: cmd_client}

    @auto_resolve(labels.ADAPTER, execution_type=constants.ExecutionType.CMD)
    def set_adapter_ip(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER, execution_type=constants.ExecutionType.CMD)
    def set_network_info(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER, execution_type=constants.ExecutionType.CMD)
    def get_adapter_ip(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER, execution_type=constants.ExecutionType.CMD)
    def get_adapter_mac(self, execution_type=None, timeout=None, **kwargs):
        pass

    def GetIPv4(self):
        return self.get_adapter_ip()

    def get_mac(self):
        return self.get_adapter_mac()

    def get_name(self):
        return self.name
