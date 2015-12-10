import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.transport_zone.transport_zone as transport_zone
import vmware.nsx.manager.transport_zone.api.transport_zone_api_client\
    as transport_zone_api_client
import vmware.nsx.manager.transport_zone.cli.transport_zone_cli_client\
    as transport_zone_cli_client
import vmware.nsx.manager.transport_zone.ui.transport_zone_ui_client\
    as transport_zone_ui_client

pylogger = global_config.pylogger


class TransportZoneFacade(transport_zone.TransportZone,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(TransportZoneFacade, self).__init__(parent)
        self.id_ = id_
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = transport_zone_api_client.TransportZoneAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=self.id_)
        cli_client = transport_zone_cli_client.TransportZoneCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI),
            id_=self.id_)
        ui_client = transport_zone_ui_client.TransportZoneUIClient(
            parent=parent.get_client(constants.ExecutionType.UI),
            id_=self.id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}
