import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.esx.vsswitch.vsswitch as vsswitch
import pyVmomi as pyVmomi

vim = pyVmomi.vim


class VSSwitchAPIClient(vsswitch.VSSwitch, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(VSSwitchAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
