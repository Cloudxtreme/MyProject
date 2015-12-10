import vmware.base.algorithm as algorithm
import vmware.nsx.manager.manager_client as manager_client


class CryptographicAlgorithmAPIClient(algorithm.Algorithm,
                                      manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(CryptographicAlgorithmAPIClient, self).__init__(parent=parent)
        self.id_ = id_
