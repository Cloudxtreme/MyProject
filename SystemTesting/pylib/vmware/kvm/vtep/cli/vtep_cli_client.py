import vmware.common.base_client as base_client
import vmware.kvm.vtep.vtep as vtep


class VTEPCLIClient(vtep.VTEP, base_client.BaseCLIClient):
    def __init__(self, parent=None, name=None):
        super(VTEPCLIClient, self).__init__(parent=parent)
        self.name = name
