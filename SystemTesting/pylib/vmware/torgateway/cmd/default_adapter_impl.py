import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.linux.cmd.linux_adapter_impl as linux_adapter_impl

LinuxAdapterImpl = linux_adapter_impl.LinuxAdapterImpl
pylogger = global_config.configure_logger()


class DefaultAdapterImpl(adapter_interface.AdapterInterface):
    """Adapter management class for Ubuntu."""
    PKG_MGR = "dpkg"
    WGET = "wget"
    APT_FORCE_STR = '-o Dpkg::Options::="--force-confnew" --yes --force-yes'
    IP_RESET_CMD = "dhclient"

    @classmethod
    def reset_adapter_ip(cls, client_object, adapter_name=None):

        if adapter_name is None:
            raise ValueError('Adapter name cannot be None')

        an = adapter_name
        nw_info = LinuxAdapterImpl.get_single_adapter_info(client_object,
                                                           adapter_name=an,
                                                           timeout=30)
        old_ip = nw_info['ip']

        dhclient_cmd = cls.IP_RESET_CMD + " " + adapter_name
        client_object.connection.request(dhclient_cmd)

        nw_info = LinuxAdapterImpl.get_single_adapter_info(client_object,
                                                           adapter_name=an,
                                                           timeout=30)
        new_ip = nw_info['ip']

        if str(new_ip) == str(old_ip) or new_ip is None:
            raise ValueError('IP was not reset.')
