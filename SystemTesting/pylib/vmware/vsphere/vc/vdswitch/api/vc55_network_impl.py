import vmware.common.constants as constants
import vmware.interfaces.network_interface as network_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config
import vmware
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class VC55NetworkImpl(network_interface.NetworkInterface):

    @classmethod
    def check_network_exists(cls, client_object, network=None):
        """
        Checks if a network exists on the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type network: str
        @param network: Name of the network

        @rtype: str
        @return: Success or Failure
        """
        vds_mor = client_object.vds_mor
        for portgroup in vds_mor.portgroup:
            if portgroup.name == network:
                return constants.Result.SUCCESS
        return constants.Result.FAILURE

    @classmethod
    def list_networks(cls, client_object):
        """
        Lists the networks on the switch.

        @type client_object: client instance
        @param client_object: VDSwitch client instance

        @rtype: list
        @return: List of networks
        """
        pg = []
        vds_mor = client_object.vds_mor
        for portgroup in vds_mor.portgroup:
            pg.append(portgroup.name)
        return pg
