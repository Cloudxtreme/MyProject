import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.linux.ovs.cli.default_crud_impl as default_crud_impl
import vmware.common.constants as constants

pylogger = global_config.pylogger
DefaultCRUDImpl = default_crud_impl.DefaultCRUDImpl


class NSX70AdapterImpl(adapter_interface.AdapterInterface):

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
        pylogger.warning('Did not find IP address for VTEP %r on %r' %
                         (client_object.name, client_object.ip))

    @classmethod
    def get_ip_address(cls, client_object):
        """
        Returns the IP address of the adapter.
        """
        return cls.get_adapter_ip(client_object)

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
        pylogger.warning('Did not find a MAC address for VTEP %r on %r' %
                         (client_object.name, client_object.ip))

    @classmethod
    def get_device_name(cls, client_object):
        return client_object.name

    @classmethod
    def get_adapter_interface(cls, client_object):
        # FIXME: this needs to return the port name like eth1 for breth1 which
        # corresponds to the physical interface name
        return client_object.name

    @classmethod
    def set_adapter_mtu(cls, client_object, mtu=None):
        mtu_cmd = "ifconfig %s mtu %s" % (client_object.name, mtu)
        return client_object.connection.request(mtu_cmd)

    @classmethod
    def get_adapter_mtu(cls, client_object):
        parsed_data = DefaultCRUDImpl.get_adapter_info(client_object)
        for record in parsed_data['table']:
            if 'dev' in record and record['dev'] == client_object.name:
                return record['mtu']
        pylogger.warning('Did not find MTU Value for VTEP %r on %r' %
                         (client_object.name, client_object.ip))

    @classmethod
    def renew_dhcp(cls, client_object):
        if not client_object.name:
            pylogger.error('Did not find client_object.name!')
            return constants.Result.FAILURE.upper()
        else:
            refresh_command = ("dhclient -r %s ; dhclient %s" %
                               (client_object.name, client_object.name))
            return client_object.connection.request(refresh_command)
