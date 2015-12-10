#!/usr/bin/env python
import vmware.base.server as server
import vmware.base.vm as vm
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class DHCPServer(server.Server, vm.VM):
    os_map = {'RedHatEnterpriseServer': 'RHEL',
              'Ubuntu': 'Ubuntu'}
    _os_version = None

    @property
    def os_version(self):
        if self._os_version:
            return self._os_version
        connection = ssh_connection.SSHConnection(
            ip=self.ip, username=self.username, password=self.password)
        connection.create_connection()
        raw_data = connection.request('lsb_release -a').response_data
        connection.close()
        lsb_info = utilities.procinfo_to_dict(raw_data)
        os_key = '%s' % lsb_info['Distributor ID']
        self._os_version = self.os_map.get(os_key, None)
        if not self._os_version:
            raise ValueError('%r is not supported' % os_key)
        return self._os_version

    def get_impl_version(self, execution_type=None, interface=None):
        return self.os_version

    @auto_resolve(labels.DHCPSERVER)
    def configure_dhcp_server(self, execution_type=None, **kwargs):
        """Configures a DHCP Server with desired parameters."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def enable_dhcp_server_on_interfaces(self, execution_type=None, **kwargs):
        """Enables DHCP Server on an interface."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def is_dhcp_server_service_installed(self, execution_type=None, **kwargs):
        """Check if DHCP Server is installed on the machine."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def setup_dhcp_server(self, execution_type=None, **kwargs):
        """Initial set up of DHCP Server using dhcpd.conf."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def restart_dhcp_server(self, execution_type=None, **kwargs):
        """ Resets a DHCP Server."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def stop_dhcp_server(self, execution_type=None, **kwargs):
        """Stops the DHCP Server."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def start_dhcp_server(self, execution_type=None, **kwargs):
        """Starts the DHCP Server."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def is_dhcp_server_enabled(self, execution_type=None, **kwargs):
        """Check if DHCP Server is running."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def disable_dhcp_server_on_interfaces(self, execution_type=None, **kwargs):
        """Disables DHCP Server on an interface."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def clear_dhcp_server_config(self, execution_type=None, **kwargs):
        """Clear DHCP Server configuration."""
        pass

    @auto_resolve(labels.OS)
    def ip_route(self, execution_type=None, **kwargs):
        """Configures routes on DHCP Server."""
        pass

    @auto_resolve(labels.OS)
    def empty_file_contents(self, execution_type=None, **kwargs):
        """Empty file contents."""
        pass

    @auto_resolve(labels.OS)
    def append_file(self, execution_type=None, **kwargs):
        """Append contents to a file."""
        pass

    @auto_resolve(labels.OS)
    def replace_regex_in_file(self, execution_type=None, **kwargs):
        """Replace matched string in a file."""
        pass
