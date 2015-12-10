import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels
import vmware.common.versions as versions

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class Cluster(base.Base):
    #
    # This is base class for all components of Cluster type.
    # e.g. ManagementCluster, ControllerCluster
    #
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE
    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Cluster, self).__init__()
        self.parent = parent

    @auto_resolve(labels.CRUD)
    def status(self, **kwargs):
        pass

    @auto_resolve(labels.CLUSTER)
    def wait_for_required_cluster_status(self, **kwargs):
        pass
