import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.ipset.api.ipset_api_client as ipset_api_client  # noqa
import vmware.nsx.manager.ipset.ipset as ipset  # noqa


pylogger = global_config.pylogger


class IPSetFacade(ipset.IPSet,
                  base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(IPSetFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = ipset_api_client.IPSetAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
