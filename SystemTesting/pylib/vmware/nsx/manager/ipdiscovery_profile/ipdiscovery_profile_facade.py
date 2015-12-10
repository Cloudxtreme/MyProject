import vmware.nsx.manager.ipdiscovery_profile.ipdiscovery_profile as ipdiscovery_profile  # noqa
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.ipdiscovery_profile.api.ipdiscovery_profile_api_client as ipdiscovery_profile_api_client  # noqa

pylogger = global_config.pylogger


class IPDiscoveryProfileFacade(ipdiscovery_profile.IPDiscoveryProfile,
                               base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(IPDiscoveryProfileFacade, self).__init__(parent=parent, id_=id_)
        api_client = ipdiscovery_profile_api_client.\
            IPDiscoveryProfileAPIClient(
                parent=parent.get_client(constants.ExecutionType.API))
        self._clients = {constants.ExecutionType.API: api_client}
