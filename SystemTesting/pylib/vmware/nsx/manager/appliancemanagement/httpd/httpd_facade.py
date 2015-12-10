import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.httpd.api.\
    httpd_api_client as httpd_api_client
import vmware.nsx.manager.appliancemanagement.httpd.cli.\
    httpd_cli_client as httpd_cli_client

pylogger = global_config.pylogger


class HttpdFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """
    HttpdFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(HttpdFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = httpd_api_client.HttpdAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = httpd_cli_client.HttpdCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
