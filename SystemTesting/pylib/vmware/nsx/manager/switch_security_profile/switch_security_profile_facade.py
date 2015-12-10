import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.switch_security_profile.api.\
    switch_security_profile_api_client as switch_security_profile_api_client
import vmware.nsx.manager.switch_security_profile.cli.\
    switch_security_profile_cli_client as switch_security_profile_cli_client

import vmware.nsx.manager.switch_security_profile.switch_security_profile\
    as switch_security_profile

pylogger = global_config.pylogger


class SwitchSecurityProfileFacade(switch_security_profile.
                                  SwitchSecurityProfile,
                                  base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(SwitchSecurityProfileFacade, self).__init__(parent=parent,
                                                          id_=id_)

        # instantiate client objects
        api_client = switch_security_profile_api_client.\
            SwitchSecurityProfileAPIClient(parent=parent.
                                           get_client(constants.
                                                      ExecutionType.API))
        cli_client = switch_security_profile_cli_client.\
            SwitchSecurityProfileCLIClient(parent=parent.
                                           get_client(constants.
                                                      ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
