import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.crl.api.crl_api_client as crl_api_client
import vmware.nsx.manager.crl.cli.crl_cli_client as crl_cli_client
import vmware.nsx.manager.crl.crl as crl

pylogger = global_config.pylogger


class CRLFacade(crl.CRL, base_facade.BaseFacade):
    """CRL facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(CRLFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        api_client = crl_api_client.CRLAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = crl_cli_client.CRLCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
