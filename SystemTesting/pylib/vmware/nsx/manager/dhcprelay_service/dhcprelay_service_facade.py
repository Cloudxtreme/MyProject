import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.dhcprelay_service.api.dhcprelay_service_api_client as dhcprelay_service_api_client  # noqa
import vmware.nsx.manager.dhcprelay_service.dhcprelay_service as dhcprelay_service  # noqa


pylogger = global_config.pylogger


class DHCPRelayServiceFacade(dhcprelay_service.DHCPRelayService,
                             base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(DHCPRelayServiceFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = dhcprelay_service_api_client.DHCPRelayServiceAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
