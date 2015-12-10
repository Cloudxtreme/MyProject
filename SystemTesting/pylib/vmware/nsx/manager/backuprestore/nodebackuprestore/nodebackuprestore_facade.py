import vmware.base.snapshot as snapshot
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.backuprestore.nodebackuprestore.api.\
    nodebackuprestore_api_client as nodebackuprestore_api_client
import vmware.nsx.manager.backuprestore.nodebackuprestore.cli.\
    nodebackuprestore_cli_client as nodebackuprestore_cli_client

pylogger = global_config.pylogger


class NodeBackupRestoreFacade(snapshot.Snapshot,
                              base_facade.BaseFacade):
    """
    NodeBackupRestoreFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(NodeBackupRestoreFacade, self).__init__(parent)
        self.id_ = id_
        self.parent = parent

        # instantiate client objects
        api_client = nodebackuprestore_api_client.NodeBackupRestoreAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=self.id_)
        cli_client = nodebackuprestore_cli_client.NodeBackupRestoreCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI),
            id_=self.id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
