import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.esx.vsswitch.portgroup.portgroup as portgroup

import pyVmomi as pyVmomi

vim = pyVmomi.vim


class PortgroupAPIClient(portgroup.Portgroup, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(PortgroupAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
