import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.ippool_allocate.api.ippool_allocate_api_client \
    as ippool_allocate_api_client
import vmware.nsx.manager.ippool_allocate.ippool_allocate as ippool_allocate

pylogger = global_config.pylogger


class IPPoolAllocateFacade(ippool_allocate.IPPoolAllocate,
                           base_facade.BaseFacade):
    """IPPool Allocate facade class to perform IP allocation"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(IPPoolAllocateFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = ippool_allocate_api_client.IPPoolAllocateAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
