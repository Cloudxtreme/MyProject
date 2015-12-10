import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.nsservice.api.nsservice_api_client as nsservice_api_client  # noqa
import vmware.nsx.manager.nsservice.nsservice as nsservice  # noqa


pylogger = global_config.pylogger


class NSServiceFacade(nsservice.NSService,
                      base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(NSServiceFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = nsservice_api_client.NSServiceAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
