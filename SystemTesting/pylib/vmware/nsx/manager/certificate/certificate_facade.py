import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.certificate.api.certificate_api_client\
    as certificate_api_client
import vmware.nsx.manager.certificate.cli.certificate_cli_client\
    as certificate_cli_client
import vmware.nsx.manager.certificate.certificate as certificate

pylogger = global_config.pylogger


class CertificateFacade(certificate.Certificate, base_facade.BaseFacade):
    """CSR facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(CertificateFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        api_client = certificate_api_client.CertificateAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = certificate_cli_client.CertificateCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
