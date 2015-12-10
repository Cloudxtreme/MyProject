import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.dhcprelay_profile.api.dhcprelay_profile_api_client as dhcprelay_profile_api_client  # noqa
import vmware.nsx.manager.dhcprelay_profile.dhcprelay_profile as dhcprelay_profile  # noqa


pylogger = global_config.pylogger


class DHCPRelayProfileFacade(dhcprelay_profile.DHCPRelayProfile,
                             base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(DHCPRelayProfileFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = dhcprelay_profile_api_client.DHCPRelayProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}