import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.csr.api.csr_api_client as csr_api_client
import vmware.nsx.manager.csr.cli.csr_cli_client as csr_cli_client
import vmware.nsx.manager.csr.csr as csr

pylogger = global_config.pylogger


class CSRFacade(csr.CSR, base_facade.BaseFacade):
    """CSR facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(CSRFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = csr_api_client.CSRAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = csr_cli_client.CSRCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
