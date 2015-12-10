import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.interface.api.\
    interface_api_client as interface_api_client
import vmware.nsx.manager.appliancemanagement.interface.cli.\
    interface_cli_client as interface_cli_client

pylogger = global_config.pylogger


class InterfaceFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """
    InterfaceFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(InterfaceFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = interface_api_client.InterfaceAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = interface_cli_client.InterfaceCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
