#!/usr/bin/env python
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels
import vmware.torgateway.torgateway as torgateway
import vmware.torgateway.cmd.torgateway_cmd_client as torgateway_cmd_client

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class TORGatewayFacade(torgateway.TORGateway, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CMD

    def __init__(self, ip=None, username=None, password=None):
        super(TORGatewayFacade, self).__init__(ip=ip, username=username,
                                               password=password)

        # instantiate client objects
        cmd_client = torgateway_cmd_client.TORGatewayCMDClient(
            ip=self.ip, username=self.username, password=self.password)
        self._clients = {constants.ExecutionType.CMD: cmd_client}

    @auto_resolve(labels.APPLIANCE, execution_type=constants.ExecutionType.CMD)
    def regenerate_certificate(self, execution_type=None, status=None,
                               **kwargs):
        pass

    @auto_resolve(labels.SERVICE, execution_type=constants.ExecutionType.CMD)
    def start_service(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD, execution_type=constants.ExecutionType.CMD)
    def get_certificate(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER, execution_type=constants.ExecutionType.CMD)
    def reset_adapter_ip(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH, execution_type=constants.ExecutionType.CMD)
    def bind_pnic(self, execution_type=None, timeout=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP, execution_type=constants.ExecutionType.CMD)
    def remove_nsx_controller(self, execution_type=None, status=None,
                              **kwargs):
        pass

    @auto_resolve(labels.POWER, execution_type=constants.ExecutionType.CMD)
    def wait_for_reboot(self, execution_type=None, timeout=None, **kwargs):
        """
        Waits for reboot on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type timeout: int
        @param timeout: Value in seconds after the wait for reboot times out.
        """
        pass

    def req_call(self, cmd, **kwargs):
        raise NotImplementedError("Implementation required in client class")


if __name__ == "__main__":
    pass
