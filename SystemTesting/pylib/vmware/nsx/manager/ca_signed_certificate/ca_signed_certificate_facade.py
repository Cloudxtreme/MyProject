import vmware.base.certificate as certificate
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.ca_signed_certificate.api.\
    ca_signed_certificate_api_client as ca_signed_certificate_api_client

pylogger = global_config.pylogger


class CASignedCertificateFacade(certificate.Certificate,
                                base_facade.BaseFacade):
    """CASignedCertificate facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(CASignedCertificateFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        api_client = ca_signed_certificate_api_client.\
            CASignedCertificateAPIClient(
                parent=parent.get_client(constants.ExecutionType.API))

        self._clients = {constants.ExecutionType.API: api_client}
