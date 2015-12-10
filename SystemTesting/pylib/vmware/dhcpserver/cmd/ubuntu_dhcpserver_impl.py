import re

import vmware.common.utilities as utilities
import vmware.interfaces.dhcpserver_interface as dhcp_server_interface


class UbuntuDHCPServerImpl(dhcp_server_interface.DHCPServerInterface):
    """DHCP Server implementation class for linux."""
    DEFAULT_LEASE = 86400
    MAX_LEASE = 604800
    DEFAULT_OPTIONS = {'default-lease-time': DEFAULT_LEASE,
                       'max-lease-time': MAX_LEASE}
    DHCPD_CONF_FILE = '/etc/dhcp/dhcpd.conf'
    IFACE_REGEX = 'INTERFACES="'
    ISC_DHCP_SERVER_FILE = '/etc/default/isc-dhcp-server'
    ISC_DHCP_SERVER_SERVICE = 'isc-dhcp-server'
    STATUS_SERVICE_RUNNING = ('start/running', 'is running')

    @classmethod
    def configure_dhcp_server(cls, client_object, ip_range=None, subnet=None,
                              netmask=None, broadcast_addr=None,
                              option_routers=None, dhcp_type=None,
                              adapter_mac=None, adapter_ip=None,
                              host_name=None, default_lease=None,
                              max_lease=None):
        """
        Configures a DHCP Server.

        """
        if dhcp_type == 'static':
            client_object.append_file(
                content=("host %s {" % host_name), path=cls.DHCPD_CONF_FILE)
            client_object.append_file(
                content=("hardware ethernet %s;" % adapter_mac),
                path=cls.DHCPD_CONF_FILE)
            client_object.append_file(
                content=("fixed-address %s;" % adapter_ip),
                path=cls.DHCPD_CONF_FILE)
        else:
            client_object.append_file(
                content=("subnet %s netmask %s {" % (subnet, netmask)),
                path=cls.DHCPD_CONF_FILE)
            if ip_range:
                ip_range = ip_range.replace(" ", "")
                ips = ip_range.split("-")
                client_object.append_file(
                    content=("range %s %s;" % (ips[0], ips[-1])),
                    path=cls.DHCPD_CONF_FILE)
        if option_routers:
            client_object.append_file(
                content=("option routers %s;" % option_routers),
                path=cls.DHCPD_CONF_FILE)
        if broadcast_addr:
            client_object.append_file(
                content=("option broadcast-address %s;" % broadcast_addr),
                path=cls.DHCPD_CONF_FILE)
        if default_lease:
            client_object.append_file(
                content=("default-lease-time %s;" % default_lease),
                path=cls.DHCPD_CONF_FILE)
        if max_lease:
            client_object.append_file(
                content=("max-lease-time %s;" % max_lease),
                path=cls.DHCPD_CONF_FILE)
        return client_object.append_file(content="}\n",
                                         path=cls.DHCPD_CONF_FILE)

    @classmethod
    def enable_dhcp_server_on_interfaces(cls, client_object,
                                         adapter_interface=None):
        if adapter_interface is None:
            adapter_interface = []
        adapter_interface = utilities.as_list(adapter_interface)
        iface_cfg = ('%s%s ' % (cls.IFACE_REGEX, ' '.join(adapter_interface)))
        return client_object.replace_regex_in_file(
            path=cls.ISC_DHCP_SERVER_FILE, find=cls.IFACE_REGEX,
            replace=iface_cfg)

    @classmethod
    def setup_dhcp_server(cls, client_object):
        """
        Sets up DHCP Server with default options.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @rtype: str
        @return: Returns the stdout after running the command.
        """
        cls.clear_dhcp_server_config(client_object)
        content = '%s"' % cls.IFACE_REGEX
        client_object.append_file(content=content,
                                  path=cls.ISC_DHCP_SERVER_FILE)
        for option in cls.DEFAULT_OPTIONS:
            content = '%s %s;' % (option, cls.DEFAULT_OPTIONS[option])
            client_object.append_file(content=content,
                                      path=cls.DHCPD_CONF_FILE)
        return client_object.append_file(content='\n',
                                         path=cls.DHCPD_CONF_FILE)

    @classmethod
    def clear_dhcp_server_config(cls, client_object):
        client_object.empty_file_contents(path=cls.DHCPD_CONF_FILE)
        return client_object.empty_file_contents(path=cls.ISC_DHCP_SERVER_FILE)

    @classmethod
    def restart_dhcp_server(cls, client_object):
        cmd = 'service isc-dhcp-server restart'
        return client_object.connection.request(cmd)

    @classmethod
    def stop_dhcp_server(cls, client_object):
        cmd = 'service isc-dhcp-server stop'
        return client_object.connection.request(cmd)

    @classmethod
    def start_dhcp_server(cls, client_object):
        cmd = 'service isc-dhcp-server start'
        return client_object.connection.request(cmd)

    @classmethod
    def disable_dhcp_server_on_interfaces(cls, client_object,
                                          adapter_interface=None):
        if adapter_interface is None:
            adapter_interface = []
        adapter_interface = utilities.as_list(adapter_interface)
        for interface in adapter_interface:
            client_object.replace_regex_in_file(path=cls.ISC_DHCP_SERVER_FILE,
                                                find=('%s ') % interface,
                                                replace='')
        return cls.restart_dhcp_server(client_object)

    @classmethod
    def is_dhcp_server_enabled(cls, client_object):
        cmd = "service %s status" % cls.ISC_DHCP_SERVER_SERVICE
        status = client_object.connection.request(cmd)
        running_strs = '(%s)' % '|'.join(cls.STATUS_SERVICE_RUNNING)
        running_re = re.compile(running_strs)
        match = running_re.search(status)
        return bool(match)

    @classmethod
    def install_dhcp_server(cls, client_object):
        client_object.update(install_from_repo=True)
        return client_object.install(resource=[cls.ISC_DHCP_SERVER_SERVICE],
                                     install_from_repo=True)
