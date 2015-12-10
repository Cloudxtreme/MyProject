import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vc.vdswitch.dvport.dvport as dvport


class DVPortAPIClient(dvport.DVPort, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(DVPortAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
