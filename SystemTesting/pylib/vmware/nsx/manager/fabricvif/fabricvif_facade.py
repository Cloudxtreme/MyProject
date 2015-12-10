import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.fabricvif.api.\
    fabricvif_api_client as fabricvif_api_client
import vmware.nsx.manager.fabricvif.fabricvif as fabricvif


class FabricVifFacade(fabricvif.FabricVif, base_facade.BaseFacade):
    """VIFInfo facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(FabricVifFacade, self).__init__(parent)
        self.parent = parent

        # instantiate client objects
        api_client = fabricvif_api_client. \
            FabricVifAPIClient(parent=parent.
                               get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
