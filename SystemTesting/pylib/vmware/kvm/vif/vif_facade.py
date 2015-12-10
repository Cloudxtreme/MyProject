import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.kvm.vif.vif as vif
import vmware.kvm.vif.api.vif_api_client as vif_api_client


class VIFFacade(vif.VIF, base_facade.BaseFacade):
    """
    Client class for KVM based VIFs.

    @type parent: BaseFacade
    @param parent: To instantiate a VIF client object, pass in the parent
        entity (in this case KVM client object) which can perform
        operations on the VIF.
    @type name: str
    @param name: Name of this VIF.
    """
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name=None, parent=None):
        super(VIFFacade, self).__init__(name=name, parent=parent)
        api_client = vif_api_client.VIFAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), name=name)
        self._clients = {constants.ExecutionType.API: api_client}
