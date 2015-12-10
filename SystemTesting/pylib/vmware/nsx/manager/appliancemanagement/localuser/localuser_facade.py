import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.localuser.api.\
    localuser_api_client as localuser_api_client
import vmware.nsx.manager.appliancemanagement.localuser.cli.\
    localuser_cli_client as localuser_cli_client

pylogger = global_config.pylogger


class LocalUserFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """
    LocalUserFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(LocalUserFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = localuser_api_client.LocalUserAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = localuser_cli_client.LocalUserCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
