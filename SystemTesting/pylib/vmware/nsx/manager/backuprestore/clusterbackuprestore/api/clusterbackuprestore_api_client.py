import vmware.base.snapshot as snapshot
import vmware.nsx.manager.manager_client as manager_client


class ClusterBackupRestoreAPIClient(snapshot.Snapshot,
                                    manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(ClusterBackupRestoreAPIClient, self).__init__(parent=parent)
        self.id_ = id_
