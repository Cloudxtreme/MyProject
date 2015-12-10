import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.auth_server.auth_server as authentication_server
import vmware.auth_server.cli.auth_server_cli_client as authentication_server_cli_client  # noqa

pylogger = global_config.pylogger


class AuthServerFacade(authentication_server.AuthServer,
                       base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, ip=None, username=None, password=None):
        super(AuthServerFacade, self).__init__(ip=ip, username=username,
                                               password=password)
        # instantiate client objects
        cli_client = authentication_server_cli_client.AuthServerCLIClient(
            ip=self.ip, username=self.username, password=self.password)

        self._clients = {constants.ExecutionType.CLI: cli_client}

    def get_ip(self):
        return self.ip
