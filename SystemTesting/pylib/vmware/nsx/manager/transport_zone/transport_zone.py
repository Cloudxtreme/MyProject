import vmware.base.zone as zone
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger


class TransportZone(zone.Zone):

    def __init__(self, parent=None):
        super(TransportZone, self).__init__(parent)
        self.parent = parent
        self.id_ = None

    @base_facade.auto_resolve(labels.CRUD)
    def get_transport_nodes(self, execution_type=None, **kwargs):
        pass

    @base_facade.auto_resolve(labels.AGGREGATION)
    def get_aggregation_status(self, execution_type=None, **kwargs):
        """
        Returns the high-level summary of a transport zone showing the number
        of up/degraded/down transport nodes.
        """
        pass
