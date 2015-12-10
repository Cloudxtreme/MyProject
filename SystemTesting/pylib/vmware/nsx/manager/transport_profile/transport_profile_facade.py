import vmware.base.node as node
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.transport_profile.api.transport_profile_api_client\
    as transport_profile_api_client
import vmware.nsx.manager.transport_profile.cli.transport_profile_cli_client\
    as transport_profile_cli_client
import vmware.nsx.manager.transport_profile.ui.transport_profile_ui_client\
    as transport_profile_ui_client


pylogger = global_config.pylogger


class TransportProfileFacade(node.Node, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(TransportProfileFacade, self).__init__(parent=parent, id_=id_)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = transport_profile_api_client.TransportProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = transport_profile_cli_client.TransportProfileCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)
        ui_client = transport_profile_ui_client.TransportProfileUIClient(
            parent=parent.get_client(constants.ExecutionType.UI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}
