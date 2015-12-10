import vmware.interfaces.hypervisor_interface as hypervisor_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class ESX55HypervisorImpl(hypervisor_interface.HypervisorInterface):
    """Hypervisor related operations."""

    @classmethod
    def update_pci_passthru(cls, client_object, vmnic_list=None, enable=None):
        """
        Updates PciPassthru configuration.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type vmnic_list: list
        @param config: List of vmnics/pnics.

        @type enable: bool
        @param enable: True or False

        @rtype: NoneType
        @return: None
        """
        host_mor = client_object.get_host_mor()
        config = []
        for vmnic in vmnic_list:
            for pnic in host_mor.configManager.networkSystem.networkInfo.pnic:
                if vmnic == pnic.device:
                    pci_config = vim.host.PciPassthruConfig()
                    pci_config.id = pnic.pci
                    pci_config.passthruEnabled = enable
                    config.append(pci_config)
        pci = host_mor.configManager.pciPassthruSystem
        pci.UpdatePassthruConfig(config)

    @classmethod
    def disconnect_host(cls, client_object):
        """
`       Disconnects host.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: str
        @return: Operation result.
        """
        host_mor = client_object.get_host_mor()
        return vc_soap_util.get_task_state(host_mor.DisconnectHost_Task())
