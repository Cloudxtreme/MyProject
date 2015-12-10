import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.uplink_profile.api.uplink_profile_api_client\
    as uplink_profile_api_client
import vmware.nsx.manager.uplink_profile.cli.uplink_profile_cli_client\
    as uplink_profile_cli_client

import vmware.nsx.manager.uplink_profile.uplink_profile\
    as uplink_profile

pylogger = global_config.pylogger


class UplinkProfileFacade(uplink_profile.UplinkProfile,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(UplinkProfileFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = uplink_profile_api_client.UplinkProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = uplink_profile_cli_client.UplinkProfileCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
