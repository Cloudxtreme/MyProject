import vmware.base.node as node
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ClusterNode(node.Node):
    DEFAULT_IMPLEMENTATION_VERSION = 'NSX70'

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION
