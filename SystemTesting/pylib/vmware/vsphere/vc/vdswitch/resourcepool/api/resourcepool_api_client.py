import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vc.vdswitch.resourcepool.resourcepool as resourcepool

import pyVmomi as pyVmomi

vim = pyVmomi.vim

class ResourcePoolAPIClient(resourcepool.ResourcePool, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(ResourcePoolAPIClient, self).__init__(parent=parent)
        self.name = name
        self.key = self.get_key()

    def get_key(self):
        for pool in self.parent.vds_mor.networkResourcePool:
            if self.name == pool.name:
                return pool.key

    def get_network_resource_pool_spec(self, **kwargs):
        spec = vim.dvs.NetworkResourcePool.ConfigSpec()
        allocation = vim.dvs.NetworkResourcePool.AllocationInfo()
        if kwargs.get('shares') is not None:
            share = vim.SharesInfo()
            share.shares = kwargs.get('shares')
            shares_level = vim.SharesInfo.Level()
            shares_level = kwargs.get('shares_level')
            share.level = shares_level
            allocation.shares = share
            spec.allocationInfo = allocation
        if kwargs.get('limit') is not None:
            allocation.limit = kwargs.get('limit')
        if kwargs.get('priority_tag') is not None:
            allocation.priorityTag = kwargs.get('priority_tag')
        if kwargs.get('config_version') is not None:
            spec.configVersion = kwargs.get('config_version')
        if kwargs.get('description') is not None:
            spec.description = kwargs.get('description')
        if kwargs.get('key') is not None:
            spec.key = kwargs.get('key')
        if kwargs.get('name') is not None:
            spec.name = kwargs.get('name')
        return spec
