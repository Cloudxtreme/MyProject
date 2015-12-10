import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.spoof_guard_profile.api.\
    spoof_guard_profile_api_client as spoof_guard_profile_api_client
import vmware.nsx.manager.spoof_guard_profile.cli.\
    spoof_guard_profile_cli_client as spoof_guard_profile_cli_client

import vmware.nsx.manager.spoof_guard_profile.spoof_guard_profile\
    as spoof_guard_profile

pylogger = global_config.pylogger


class SpoofGuardProfileFacade(spoof_guard_profile.SpoofGuardProfile,
                              base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(SpoofGuardProfileFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = spoof_guard_profile_api_client.\
            SpoofGuardProfileAPIClient(parent=parent.
                                       get_client(constants.
                                                  ExecutionType.API))
        cli_client = spoof_guard_profile_cli_client.\
            SpoofGuardProfileCLIClient(parent=parent.
                                       get_client(constants.
                                                  ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
