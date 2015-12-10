import vmware.base.pool as pool
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.vnipool.api.vnipool_api_client\
    as vnipool_api_client

pylogger = global_config.pylogger


class VNIPoolFacade(pool.Pool, base_facade.BaseFacade):
    """VNI Pool facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(VNIPoolFacade, self).__init__(parent)
        self.parent = parent
        self.nsx_manager_obj = parent
        api_client = vnipool_api_client.VNIPoolAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        self._clients = {constants.ExecutionType.API: api_client}

    def get_vnipool_id(self):
        return self.id_