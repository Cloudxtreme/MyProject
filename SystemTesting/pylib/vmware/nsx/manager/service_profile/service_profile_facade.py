import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.service_profile.api.service_profile_api_client \
    as service_profile_api_client
import vmware.nsx.manager.service_profile.cli.service_profile_cli_client \
    as service_profile_cli_client
import vmware.nsx.manager.service_profile.service_profile \
    as service_profile


pylogger = global_config.pylogger


class ServiceProfileFacade(service_profile.ServiceProfile,
                           base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(ServiceProfileFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = service_profile_api_client.ServiceProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = service_profile_cli_client.ServiceProfileCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}