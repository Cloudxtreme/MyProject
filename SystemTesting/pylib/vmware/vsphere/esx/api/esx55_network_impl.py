import vmware.interfaces.network_interface as network_interface
import vmware.common.global_config as global_config
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class ESX55NetworkImpl(network_interface.NetworkInterface):
    """Network related operations."""

    @classmethod
    def list_networks(cls, client_object):
        """
        Returns the list of port groups.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: list
        @return: List of port groups.
        """
        pg_list = []
        network_sys = client_object.get_network_system()
        for pg in network_sys.networkInfo.portgroup:
            pg_list.append(pg.spec.name)
        return pg_list

    @classmethod
    def get_dvpg_id_from_name(cls, client_object, dvs=None, dvpg=None):
        """
        Returns the ID(key) of the dvpg on the dvs.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type dvs: str
        @param dvs: Name of DVSwitch

        @type dvpg: str
        @param dvpg: Name of DVPortgroup

        @rtype: str
        @return: ID(Key) of dvpg on the DVSwitch
        """
        host_mor = client_object.get_host_mor()
        network_folder = host_mor.parent.parent.parent.networkFolder
        for component in network_folder.childEntity:
            if(isinstance(component, vim.DistributedVirtualSwitch)):
                        if component.name == dvs:
                            for host in component.summary.host:
                                if host.name == host_mor.name:
                                    for portgroup in component.portgroup:
                                        if portgroup.name == dvpg:
                                            return portgroup.key
        raise Exception("Could not retrieve ID of %s on %s" % (dvpg, dvs))
