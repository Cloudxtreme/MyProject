import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.torgateway.cmd.default_adapter_impl as default_adapter_impl

pylogger = global_config.configure_logger()
DefaultAdapterImpl = default_adapter_impl.DefaultAdapterImpl


class Ubuntu1204AdapterImpl(adapter_interface.AdapterInterface):
    """Adapter management class for Ubuntu."""

    @classmethod
    def reset_adapter_ip(cls, client_object, name=None):
        DefaultAdapterImpl.reset_adapter_ip(client_object, name)
