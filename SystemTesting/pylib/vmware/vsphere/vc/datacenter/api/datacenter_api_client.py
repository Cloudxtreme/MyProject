import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vc.datacenter.datacenter as datacenter

import pyVmomi as pyVmomi

vim = pyVmomi.vim
VSphereAPIClient = vsphere_client.VSphereAPIClient


class DatacenterAPIClient(datacenter.Datacenter, VSphereAPIClient):

    def __init__(self, parent=None, name=None):
        super(DatacenterAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
        self.datacenter_mor = None

    # TODO: Negative test the logic for nested folder structure
    def get_datacenter_mor(self, return_value=0):
        content = self.connection.anchor.RetrieveContent()
        for datacenter in content.rootFolder.childEntity:
            if isinstance(datacenter, vim.Datacenter):
                if datacenter.name == self.name:
                    return datacenter
            elif isinstance(datacenter, vim.Folder):
                child = self._recurse(datacenter)
                if isinstance(child, vim.Datacenter):
                    if child.name == self.name:
                        return child
        if return_value == 1:
            return None
        raise Exception("%r not found" % (self.name))

    def _recurse(cls, entity):
        """Helper to recurse through nested folders"""
        for child in entity.childEntity:
            if isinstance(child, vim.Folder):
                child = cls._recurse(child)
                return child
            elif isinstance(child, vim.Datacenter):
                return child
