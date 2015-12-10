import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.linuxrouter.linuxrouter as linuxrouter
import vmware.linuxrouter.cmd.linuxrouter_cmd_client as linuxrouter_cmd_client

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class LinuxRouterFacade(linuxrouter.LinuxRouter, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CMD

    def __init__(self, ip=None, username=None, password=None):
        super(LinuxRouterFacade, self).__init__(ip=ip, username=username,
                                                password=password)
        # instantiate client objects
        cmd_client = linuxrouter_cmd_client.LinuxRouterCMDClient(
            ip=self.ip, username=self.username, password=self.password)
        self._clients = {constants.ExecutionType.CMD: cmd_client}
