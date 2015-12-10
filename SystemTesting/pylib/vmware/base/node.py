import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels
import vmware.common.global_config as global_config

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class Node(base.Base):
    #
    # This is base class for all components of Node type.
    # e.g. ManagementClusterNode, ControllerClusterNode
    #

    display_name = None
    description = None
    id_ = None

    def __init__(self, parent=None, id_=None):
        super(Node, self).__init__()
        if parent is not None:
            self.parent = parent
        if id_ is not None:
            self.id_ = id_

    def get_id(self, execution_type=None, **kwargs):
        return self.id_

    def get_id_(self, execution_type=None, **kwargs):
        return self.get_id(execution_type=execution_type, **kwargs)

    def get_node_id(self, execution_type=None, **kwargs):
        return self.get_id(execution_type=execution_type, **kwargs)

    @auto_resolve(labels.CRUD)
    def create(self, execution_type=None, schema=None, **kwargs):
        pass

    @auto_resolve(labels.NODE)
    def get_cluster_node(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.NODE)
    def get_controller_vif(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.NODE)
    def get_cluster_startupnodes(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.NODE)
    def get_cluster_managers(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_switch_ports(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CLUSTER)
    def revoke_cluster_node(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_aggregation_status(self, execution_type=None, **kwargs):
        """
        Get the status for a given node as reported by aggregation service.
        """
        pass
