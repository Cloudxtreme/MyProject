import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.fabric_profile.fabric_profile as fabric_profile
import vmware.nsx.manager.fabric_profile.api.fabric_profile_api_client \
    as fabric_profile_api_client
import vmware.nsx.manager.fabric_profile.cli.fabric_profile_cli_client \
    as fabric_profile_cli_client
import vmware.nsx.manager.fabric_profile.ui.fabric_profile_ui_client \
    as fabric_profile_ui_client


class FabricProfileFacade(fabric_profile.FabricProfile,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(FabricProfileFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = fabric_profile_api_client.FabricProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = fabric_profile_cli_client.FabricProfileCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)
        ui_client = fabric_profile_ui_client.FabricProfileUIClient(
            parent=parent.get_client(constants.ExecutionType.UI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}
