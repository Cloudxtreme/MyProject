import vmware.interfaces.adapter_interface as adapter_interface
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ESX55AdapterImpl(adapter_interface.AdapterInterface):
    """Adapter related operations."""

    @classmethod
    def _get_network_system(cls, client_object):
        """Helper to get network system mor."""
        host_mor = client_object.get_host_mor()
        network_sys = host_mor.configManager.networkSystem
        return network_sys

    @classmethod
    def list_vnic(cls, client_object):
        """
        Returns a list of virtual nics on the client.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: list
        @return: List of virtual nics on the hypervisor.
        """
        nics = []
        network_sys = cls._get_network_system(client_object)
        for nic in network_sys.networkInfo.vnic:
            nics.append(nic)
        return nics

    @classmethod
    def list_pnic(cls, client_object):
        """
        Returns a list of physical nics on the client.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: list
        @return: List of physical nics on the hypervisor.
        """
        nics = []
        network_sys = cls._get_network_system(client_object)
        for nic in network_sys.networkInfo.pnic:
            nics.append(nic)
        return nics

    @classmethod
    def remove_vnic(cls, client_object, name=None):
        """Removes the virtual nic present on the host.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type name: str
        @param name: device name to be removed.

        @rtype: NoneType
        @return: None
        """
        network_sys = cls._get_network_system(client_object)
        network_sys.RemoveVirtualNic(name)

    @classmethod
    def get_pnics(cls, client_object):
        """Returns list of pnics  on the host"

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: vim.host.PhysicalNic instance
        @return: List of vim.host.PhysicalNic instances on the host
        """
        pnics = []
        network_sys = cls._get_network_system(client_object)
        for pnic in network_sys.networkInfo.pnic:
            pnics.append(pnic)
        return pnics
        raise Exception("Could not retrieve list of pnic objects on host %s"
                        % (client_object.ip))
