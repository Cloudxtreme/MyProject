import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.lldp_profile.api.lldp_profile_api_client\
    as lldp_profile_api_client
import vmware.nsx.manager.lldp_profile.lldp_profile\
    as lldp_profile

pylogger = global_config.pylogger


class LldpProfileFacade(lldp_profile.LldpProfile,
                        base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(LldpProfileFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = lldp_profile_api_client.LldpProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}