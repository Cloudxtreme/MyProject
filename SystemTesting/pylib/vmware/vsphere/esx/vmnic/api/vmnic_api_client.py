import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.esx.vmnic.vmnic as vmnic


class VmnicAPIClient(vmnic.Vmnic, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(VmnicAPIClient, self).__init__(parent=parent)
        self.name = name
