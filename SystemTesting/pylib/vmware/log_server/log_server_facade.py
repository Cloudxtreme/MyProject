import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.log_server.log_server as logging_server
import vmware.log_server.api.log_server_api_client as logging_server_api_client  # noqa

pylogger = global_config.pylogger


class LogServerFacade(logging_server.LogServer, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "LOGINSIGHT23"

    def __init__(self, ip=None, username=None, password=None):
        super(LogServerFacade, self).__init__(ip=ip, username=username,
                                              password=password)
        # instantiate client objects
        api_client = logging_server_api_client.LogServerAPIClient(
            ip=self.ip, username=self.username, password=self.password)
        self._clients = {constants.ExecutionType.API: api_client}
