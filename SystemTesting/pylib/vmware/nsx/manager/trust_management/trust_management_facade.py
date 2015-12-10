import vmware.base.certificate as certificate
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.trust_management.api.trust_management_api_client\
    as trust_management_api_client
pylogger = global_config.pylogger


class TrustManagementFacade(certificate.Certificate, base_facade.BaseFacade):
    """TrustManagement facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(TrustManagementFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        api_client = trust_management_api_client.TrustManagementAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        self._clients = {constants.ExecutionType.API: api_client}
