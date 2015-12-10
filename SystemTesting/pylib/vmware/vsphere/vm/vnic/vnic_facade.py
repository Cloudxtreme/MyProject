import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vm.vnic.vnic as vnic
import vmware.vsphere.vm.vnic.api.vnic_api_client as vnic_api_client


class VnicFacade(vnic.Vnic, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent, adapter_ip, adapter_mac, adapter_interface):
        super(VnicFacade, self).__init__(parent=parent)
        self.adapter_ip = adapter_ip
        self.adapter_mac = adapter_mac
        api_client = vnic_api_client.VnicAPIClient(
            parent.clients.get(constants.ExecutionType.API), adapter_ip,
            adapter_mac, adapter_interface)
        self._clients = {constants.ExecutionType.API: api_client}
