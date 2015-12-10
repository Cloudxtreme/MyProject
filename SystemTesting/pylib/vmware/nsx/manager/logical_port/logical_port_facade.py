import vmware.base.port as port
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.logical_port.api.logical_port_api_client\
    as logical_port_api_client
import vmware.nsx.manager.logical_port.cli.logical_port_cli_client\
    as logical_port_cli_client
import vmware.nsx.manager.logical_port.ui.logical_port_ui_client\
    as logical_port_ui_client


pylogger = global_config.pylogger


class LogicalPortFacade(port.Port, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(LogicalPortFacade, self).__init__(parent)
        self.id_ = id_
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = logical_port_api_client.LogicalPortAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = logical_port_cli_client.LogicalPortCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))
        ui_client = logical_port_ui_client.LogicalPortUIClient(
            parent=parent.get_client(constants.ExecutionType.UI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}
