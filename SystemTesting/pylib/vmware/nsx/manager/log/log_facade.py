
import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.log.api.log_api_client as log_api_client
import vmware.nsx.manager.log.cli.log_cli_client as log_cli_client


pylogger = global_config.pylogger


class LogFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """ Log Facade
    """
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(LogFacade, self).__init__(parent)
        self.id_ = id_
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = log_api_client.LogAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=self.id_)
        cli_client = log_cli_client.LogCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI),
            id_=self.id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}