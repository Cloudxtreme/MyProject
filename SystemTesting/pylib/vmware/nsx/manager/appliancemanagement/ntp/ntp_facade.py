import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.ntp.api.ntp_api_client \
    as ntp_api_client
import vmware.nsx.manager.appliancemanagement.ntp.cli.ntp_cli_client \
    as ntp_cli_client

pylogger = global_config.pylogger


class NtpFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):

    """
    Ntpfacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(NtpFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = ntp_api_client.NtpAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = ntp_cli_client.NtpCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
