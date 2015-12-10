import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.linux.ovs.cli.default_crud_impl as default_crud_impl

pylogger = global_config.configure_logger()
DefaultCRUDImpl = default_crud_impl.DefaultCRUDImpl


class DefaultAdapterImpl(adapter_interface.AdapterInterface):
    """Adapter management class for Ubuntu."""
    IP_SET_CMD = "ifconfig"

    @classmethod
    def set_adapter_ip(cls, client_object, adapter_ip=None):

        if adapter_ip is None:
            raise ValueError('Adapter ip cannot be None')

        ifconfig_cmd = cls.IP_SET_CMD + " " + str(client_object.name)
        ifconfig_cmd = ifconfig_cmd + " " + adapter_ip
        pylogger.debug('Setting ip with command: %s' % ifconfig_cmd)
        client_object.connection.request(ifconfig_cmd)

    @classmethod
    def set_network_info(cls, client_object, adapter_ip=None, netmask=None):

        if adapter_ip is None:
            raise ValueError('Adapter ip cannot be None')

        ifconfig_cmd = cls.IP_SET_CMD + " " + str(client_object.name)
        ifconfig_cmd = ifconfig_cmd + " " + adapter_ip

        if netmask is not None:
            ifconfig_cmd = ifconfig_cmd + " netmask " + netmask

        pylogger.debug('Setting network info with command: %s' % ifconfig_cmd)
        client_object.connection.request(ifconfig_cmd)

    @classmethod
    def get_adapter_ip(cls, client_object):
        """
        Returns the IP address of the adapter.
        """
        parsed_data = DefaultCRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['dev'] == client_object.name:
                return record['ip']
        pylogger.warning('Did not find IP address for adapter %r on %r' %
                         (client_object.name, client_object.ip))

    @classmethod
    def get_adapter_mac(cls, client_object):
        """
        Returns the MAC address of the adapter.
        """
        parsed_data = DefaultCRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['dev'] == client_object.name:
                return record['mac']
        pylogger.warning('Did not find a MAC address for adapter %r on %r' %
                         (client_object.name, client_object.ip))
