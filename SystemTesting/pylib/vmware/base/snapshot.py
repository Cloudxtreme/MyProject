import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class Snapshot(base.Base):

    #
    # This is base class for all components of Snapshot type.
    #

    def __init__(self, parent=None):
        super(Snapshot, self).__init__()
        self.parent = parent
        self.id_ = None

    @auto_resolve(labels.SNAPSHOT)
    def restore(self, execution_type=None, **kwargs):
        """
        Restore snapshot file on NSXManager

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.SNAPSHOT)
    def download(self, execution_type=None, **kwargs):
        """
        Download snapshot file from NSX Manager

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    def get_id_(self, execution_type=None, **kwargs):
        return self.id_

    @auto_resolve(labels.SNAPSHOT)
    def purge(self, execution_type=None, **kwargs):
        """
        Purge all snapshots on NSXManager

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass