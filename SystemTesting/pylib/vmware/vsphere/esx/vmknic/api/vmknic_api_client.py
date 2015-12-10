import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.esx.vmknic.vmknic as vmknic

class VmknicAPIClient(vmknic.Vmknic, vsphere_client.VSphereAPIClient):


    def __init__(self, name, parent=None):
        super(VmknicAPIClient, self).__init__(parent=parent)
        self.name = name
