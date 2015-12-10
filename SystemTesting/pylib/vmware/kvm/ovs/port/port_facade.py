import vmware.base.port as port
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.kvm.ovs.port.cli.port_cli_client as port_cli_client


class PortFacade(port.Port, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI
    DEFAULT_IMPLEMENTATION_VERSION = 'Default'

    def __init__(self, parent, name=None):
        cli_client = port_cli_client.PortCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), name=name)
        self._clients = {constants.ExecutionType.CLI: cli_client}
