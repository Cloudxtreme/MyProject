import vmware.base.messaging as messaging
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.messaging.api.messaging_api_client\
    as messaging_api_client
pylogger = global_config.pylogger


class MessagingFacade(messaging.Messaging, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(MessagingFacade, self).__init__(parent)
        self.nsx_manager_obj = parent
        self.id_ = id_

        api_client = messaging_api_client.MessagingAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)

        self._clients = {constants.ExecutionType.API: api_client}

    def get_client_id(self):
        return self.id_