import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.firewall.excludelist.api.excludelist_api_client as excludelist_api_client  # noqa
import vmware.nsx.manager.firewall.excludelist.excludelist as excludelist  # noqa


pylogger = global_config.pylogger


class ExcludeListFacade(excludelist.ExcludeList,
                        base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(ExcludeListFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = excludelist_api_client.ExcludeListAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
