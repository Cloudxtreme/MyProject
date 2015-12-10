import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vmnic.vmnic as vmnic
import vmware.vsphere.esx.vmnic.api.vmnic_api_client as vmnic_api_client


class VmnicFacade(vmnic.Vmnic, base_facade.BaseFacade):
    """Vmknic client class to initiate VM operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name, parent):
        super(VmnicFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = vmnic_api_client.VmnicAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"
