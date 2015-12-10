import ssl

import vmware.common.constants as constants
import vmware.vsphere.vc.vc as vc
import vmware.vsphere.vsphere_client as vsphere_client
import vmware.common.connections.soap_connection as soap_connection
import vmware.common.global_config as global_config
import pyVmomi as pyVmomi

pylogger = global_config.pylogger
vim = pyVmomi.vim


class VCAPIClient(vc.VC, vsphere_client.VSphereAPIClient):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, ip=None, username=None, password=None):
        ssl._create_default_https_context = ssl._create_unverified_context
        super(VCAPIClient, self).__init__(
            ip=ip, username=username, password=password)

    def get_connection(self):
        return soap_connection.SOAPConnection(self.ip, self.username,
                                              self.password)

    # TODO: Negative test this logic for nested folder structure
    def get_mor(self, host_ip):
        content = self.connection.anchor.RetrieveContent()
        search = content.searchIndex
        return search.FindByIp(ip=host_ip, vmSearch=False)

    def _recurse(self, entity):
        """Helper to recurse through nested folders"""
        for child in entity.childEntity:
            if isinstance(child, vim.Folder):
                child = self._recurse(child)
                return child
            elif isinstance(child, vim.Datacenter):
                return child

    def get_network_system(self):
        host_mor = self.get_mor()
        return host_mor.configManager.networkSystem

    def get_dvs_manager_mor(self):
        content = self.connection.anchor.RetrieveContent()
        return content.dvSwitchManager

    def get_root_folder(self):
        content = self.connection.anchor.RetrieveContent()
        return content.rootFolder

    def find_vm_using_vc(self, vm_obj, entity):
        """Helper method to retrieve VM mor"""
        if isinstance(entity, vim.Datacenter):
            for network in entity.network:
                for vm in network.vm:
                    if vm.summary.config.vmPathName == vm_obj.vmx:
                        return vm
        elif isinstance(entity, vim.Folder):
            for child in entity.childEntity:
                return self.find_vm_using_vc(vm_obj, child)

    def get_vm_mor(self, vm_obj, return_value=0):
        '''Method to retrieve VM mor through the VC.'''
        content = self.connection.anchor.RetrieveContent()
        for child in content.rootFolder.childEntity:
            vm = self.find_vm_using_vc(vm_obj, child)
            if vm is not None:
                return vm
        if return_value == 1:
            return None
        raise Exception("Could not find VM \"%s\" in the inventory"
                        % vm_obj.vmx)

    def get_folder(self, name=None, return_value=0):
        """Retrieves a folder mor by its name"""

        def find_folder(self, component, name):
            """Helper to recurse through nested folder structures"""
            if (isinstance(component, vim.Folder) and
                    component.name == name):
                return component
            else:
                if hasattr(component, 'childEntity'):
                    for entity in component.childEntity:
                        return find_folder(self, entity, name)

        root_folder = self.get_root_folder()
        for component in root_folder.childEntity:
            folder_mor = find_folder(self, component, name)
            if folder_mor:
                return folder_mor
        if return_value == 1:
            return None
        raise Exception("Could not find folder %s in the inventory"
                        % name)
