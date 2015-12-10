import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.esx.vtep.vtep as vtep


class VTEPCLIClient(vtep.VTEP, vsphere_client.VSphereCLIClient):
    pass
