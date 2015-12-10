import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.esx.vmnic.vmnic as vmnic


class VmnicCLIClient(vmnic.Vmnic, vsphere_client.VSphereCLIClient):

    def __init__(self, name, parent=None):
        super(VmnicCLIClient, self).__init__(parent=parent)
        self.name = name
