import vmware.base.certificate as certificate
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.self_signed_certificate.api.\
    self_signed_certificate_api_client as self_signed_certificate_api_client

pylogger = global_config.pylogger


class SelfSignedCertificateFacade(certificate.Certificate,
                                  base_facade.BaseFacade):
    """SelfSignedCertificate facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(SelfSignedCertificateFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        api_client = self_signed_certificate_api_client.\
            SelfSignedCertificateAPIClient(
                parent=parent.get_client(constants.ExecutionType.API))

        self._clients = {constants.ExecutionType.API: api_client}
