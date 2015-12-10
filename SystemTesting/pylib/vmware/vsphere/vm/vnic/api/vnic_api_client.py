import vmware.common.constants as constants
import vmware.vsphere.vm.vnic.vnic as vnic
import vmware.vsphere.vsphere_client as vsphere_client


class VnicAPIClient(vnic.Vnic, vsphere_client.VSphereAPIClient):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, adapter_ip=None, adapter_mac=None,
                 adapter_interface=None):
        super(VnicAPIClient, self).__init__(parent=parent)
        self.adapter_ip = adapter_ip
        self.adapter_mac = adapter_mac
        self.adapter_interface = adapter_interface
