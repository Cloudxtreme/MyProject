"""Interface class to implement dhcp server related operations."""


class DHCPServerInterface(object):

    @classmethod
    def configure_dhcp_server(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def enable_dhcp_server_on_interfaces(cls, client_object,
                                         adapter_interface=None,
                                         **kwargs):
        raise NotImplementedError

    @classmethod
    def is_dhcp_server_service_installed(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def setup_dhcp_server(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def restart_dhcp_server(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def stop_dhcp_server(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def start_dhcp_server(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def disable_dhcp_server_on_interfaces(cls, client_object,
                                          adapter_interface=None,
                                          **kwargs):
        raise NotImplementedError

    @classmethod
    def is_dhcp_server_enabled(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def clear_dhcp_server_config(cls, client_object, **kwargs):
        raise NotImplementedError
