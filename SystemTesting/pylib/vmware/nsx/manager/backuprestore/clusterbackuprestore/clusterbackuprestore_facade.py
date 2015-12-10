import vmware.base.snapshot as snapshot
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.backuprestore.clusterbackuprestore.api.\
    clusterbackuprestore_api_client as clusterbackuprestore_api_client
import vmware.nsx.manager.backuprestore.clusterbackuprestore.cli.\
    clusterbackuprestore_cli_client as clusterbackuprestore_cli_client

pylogger = global_config.pylogger


class ClusterBackupRestoreFacade(snapshot.Snapshot,
                                 base_facade.BaseFacade):
    """
    ClusterBackupRestoreFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(ClusterBackupRestoreFacade, self).__init__(parent)
        self.id_ = id_
        self.parent = parent

        # instantiate client objects
        api_client = clusterbackuprestore_api_client.\
            ClusterBackupRestoreAPIClient(parent=parent.
                                          get_client(constants.
                                                     ExecutionType.API),
                                          id_=self.id_)
        cli_client = clusterbackuprestore_cli_client.\
            ClusterBackupRestoreCLIClient(parent=parent.
                                          get_client(constants.
                                                     ExecutionType.CLI),
                                          id_=self.id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}