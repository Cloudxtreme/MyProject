import vmware.base.snapshot as snapshot
import vmware.nsx.manager.manager_client as manager_client


class NodeBackupRestoreAPIClient(snapshot.Snapshot,
                                 manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(NodeBackupRestoreAPIClient, self).__init__(parent=parent)
        self.id_ = id_
