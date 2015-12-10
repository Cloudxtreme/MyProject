import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.nsgroup.api.nsgroup_api_client as nsgroup_api_client  # noqa
import vmware.nsx.manager.nsgroup.nsgroup as nsgroup  # noqa


pylogger = global_config.pylogger


class NSGroupFacade(nsgroup.NSGroup,
                    base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(NSGroupFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = nsgroup_api_client.NSGroupAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
