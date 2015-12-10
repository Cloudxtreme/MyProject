import vmware.base.algorithm as algorithm
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.cryptographic_algorithm.api.\
    cryptographic_algorithm_api_client\
    as cryptographic_algorithm_api_client

pylogger = global_config.pylogger


class CryptographicAlgorithmFacade(algorithm.Algorithm,
                                   base_facade.BaseFacade):
    """CryptographicAlgorithmFacade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(CryptographicAlgorithmFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        api_client = cryptographic_algorithm_api_client.\
            CryptographicAlgorithmAPIClient(
                parent=parent.get_client(constants.ExecutionType.API), id_=id_)

        self._clients = {constants.ExecutionType.API: api_client}
