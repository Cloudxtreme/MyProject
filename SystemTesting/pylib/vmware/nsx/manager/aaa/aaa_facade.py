import vmware.base.auth as auth
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.aaa.api.aaa_api_client as aaa_api_client
import vmware.nsx.manager.aaa.cli.aaa_cli_client as aaa_cli_client

pylogger = global_config.pylogger


class AAAFacade(auth.Auth, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(AAAFacade, self).__init__(parent)
        self.nsx_manager_obj = parent
        self.id_ = id_

        # instantiate client objects
        api_client = aaa_api_client.AAAAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = aaa_cli_client.AAACLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
