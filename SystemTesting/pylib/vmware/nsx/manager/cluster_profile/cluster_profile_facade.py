import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.cluster_profile.cluster_profile as cluster_profile
import vmware.nsx.manager.cluster_profile.api.cluster_profile_api_client \
    as cluster_profile_api_client
import vmware.nsx.manager.cluster_profile.cli.cluster_profile_cli_client \
    as cluster_profile_cli_client
import vmware.nsx.manager.cluster_profile.ui.cluster_profile_ui_client \
    as cluster_profile_ui_client


class ClusterProfileFacade(cluster_profile.ClusterProfile,
                           base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(ClusterProfileFacade, self).__init__(parent=parent, id_=id_)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = cluster_profile_api_client.ClusterProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = cluster_profile_cli_client.ClusterProfileCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)
        ui_client = cluster_profile_ui_client.ClusterProfileUIClient(
            parent=parent.get_client(constants.ExecutionType.UI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}
