import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.process.api.\
    process_api_client as process_api_client
import vmware.nsx.manager.appliancemanagement.process.cli.\
    process_cli_client as process_cli_client

pylogger = global_config.pylogger


class ProcessFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """
    ProcessFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(ProcessFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = process_api_client.ProcessAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = process_cli_client.ProcessCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
