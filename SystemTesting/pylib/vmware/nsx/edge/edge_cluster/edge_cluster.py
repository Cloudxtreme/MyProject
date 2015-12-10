import vmware.base.gateway as gateway
import vmware.common.versions as versions


class EdgeCluster(gateway.Gateway):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None):
        super(EdgeCluster, self).__init__()
        self.parent = parent
        self.id_ = None

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def get_id_(self):
        return self.id_

    def get_cluster_id(self):
        return self.id_