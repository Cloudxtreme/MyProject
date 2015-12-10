import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.torgateway.tor_port.cmd.default_adapter_impl as \
    default_adapter_impl

pylogger = global_config.configure_logger()
DefaultAdapterImpl = default_adapter_impl.DefaultAdapterImpl


class Ubuntu1204AdapterImpl(adapter_interface.AdapterInterface):
    """Adapter management class for Ubuntu."""

    @classmethod
    def set_adapter_ip(cls, client_object, adapter_ip=None):
        DefaultAdapterImpl.set_adapter_ip(client_object, adapter_ip)

    @classmethod
    def set_network_info(cls, client_object, adapter_ip=None, netmask=None):
        DefaultAdapterImpl.set_network_info(client_object, adapter_ip, netmask)

    @classmethod
    def get_adapter_ip(cls, client_object):
        DefaultAdapterImpl.get_adapter_ip(client_object)

    @classmethod
    def get_adapter_mac(cls, client_object):
        DefaultAdapterImpl.get_adapter_mac(client_object)
