import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.dhcpserver.dhcpserver as dhcpserver
import vmware.dhcpserver.cmd.dhcpserver_cmd_client as dhcpserver_cmd_client

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class DHCPServerFacade(dhcpserver.DHCPServer, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CMD

    def __init__(self, ip=None, username=None, password=None):
        super(DHCPServerFacade, self).__init__(ip=ip, username=username,
                                               password=password)
        # instantiate client objects
        cmd_client = dhcpserver_cmd_client.DHCPServerCMDClient(
            ip=self.ip, username=self.username, password=self.password)
        self._clients = {constants.ExecutionType.CMD: cmd_client}
