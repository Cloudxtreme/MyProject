import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.kvm.ovs.bridge.bridge as bridge
import vmware.kvm.ovs.bridge.cli.bridge_cli_client as bridge_cli_client
import vmware.kvm.ovs.bridge.api.bridge_api_client as bridge_api_client


class BridgeFacade(bridge.Bridge, base_facade.BaseFacade):
    """
    Facade class for KVM based OVS bridges.

    @type parent: BaseFacade
    @param parent: To instantiate a Bridge client object, pass in the parent
        entity (in this case KVM client object) which can perform
        operations on the Bridge.
    @type name: str
    @param name: Name of this Bridge.
    """
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None):
        super(BridgeFacade, self).__init__()
        self.name = name
        self.parent = parent
        cli_client = bridge_cli_client.BridgeCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), name=name)
        api_client = bridge_api_client.BridgeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), name=name)
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
