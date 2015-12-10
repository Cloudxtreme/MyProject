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


class LinuxRouter(server.Server, vm.VM):
    # XXX(dbadiani): Only Ubuntu supported currently. Other 2 options are
    # dummy values and will be supported in future.
    os_map = {'Ubuntu': 'Ubuntu',
              'Rhel': 'Rhel'}
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
        if lsb_info['Distributor ID'] is None:
            raise ValueError("Distributor ID on Linux platform is %r" %
                             lsb_info['Distributor ID'])
        os_key = '%s' % lsb_info['Distributor ID']
        self._os_version = self.os_map.get(os_key)
        if not self._os_version:
            raise ValueError("Linux platform %r is currently not supported" %
                             os_key)
        return self._os_version

    def get_impl_version(self, execution_type=None, interface=None):
        return self.os_version

    @auto_resolve(labels.ROUTER)
    def enable_routing(self, execution_type=None, **kwargs):
        """
        Enable the routing daemon, if any, on the router.
        For e.g.: On Linux, if we use quagga, we need to enable 'zebra' daemon
        to leverage routing.
        """
        pass

    @auto_resolve(labels.ROUTER)
    def disable_routing(self, execution_type=None, clear_config=False,
                        **kwargs):
        """
        Disable the routing daemon, if any, on the router.
        For e.g.: On Linux, if we use quagga, we need to disable 'zebra' daemon
        to disable routing.
        """
        pass

    @auto_resolve(labels.ROUTER)
    def configure_interface(self, execution_type=None, **kwargs):
        """
        Configure interface IP address and other parameters for the router
        """
        pass

    @auto_resolve(labels.ROUTER)
    def enable_bgp(self, execution_type=None, **kwargs):
        """Enable BGP routing on the router."""
        pass

    @auto_resolve(labels.ROUTER)
    def disable_bgp(self, execution_type=None, clear_config=False, **kwargs):
        """Disable BGP routing on the router."""
        pass

    @auto_resolve(labels.ROUTER)
    def configure_bgp(self, execution_type=None, **kwargs):
        """Configure BGP parameters on the router"""
        pass
