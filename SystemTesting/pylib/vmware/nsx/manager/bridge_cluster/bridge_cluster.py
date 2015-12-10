import vmware.base.cluster as cluster
import vmware.common.versions as versions


class BridgeCluster(cluster.Cluster):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(BridgeCluster, self).__init__(parent=parent)
        self.id_ = id_

    def get_id(self):
        return self.id_
