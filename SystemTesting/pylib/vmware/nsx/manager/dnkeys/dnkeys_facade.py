import vmware.base.key as key
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.dnkeys.api.dnkeys_api_client as dnkeys_api_client

pylogger = global_config.pylogger


class DNKeysFacade(key.Key, base_facade.BaseFacade):
    """DNKeys facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(DNKeysFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = dnkeys_api_client.DNKeysAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
