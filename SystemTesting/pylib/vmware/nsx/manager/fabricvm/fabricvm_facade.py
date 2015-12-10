import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.fabricvm.api.\
    fabricvm_api_client as fabricvm_api_client
import vmware.nsx.manager.fabricvm.fabricvm as fabricvm


class FabricVmFacade(fabricvm.FabricVm, base_facade.BaseFacade):
    """FabricVmFacade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(FabricVmFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = fabricvm_api_client.FabricVmAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
