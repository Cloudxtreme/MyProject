
import schema.backup_request_schema as backuprequestschema
import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

import vmware.nsx_api.manager.clusterbackup.issueclusterbackuprequest \
    as issueclusterbackuprequest
import vmware.nsx_api.manager.clusterbackup.listclusterbackups \
    as listclusterbackups
import vmware.nsx_api.manager.clusterbackup.schema.\
    clusterbackuplistresult_schema as clusterbackuplistresult_schema
import vmware.nsx_api.manager.clusterbackup.schema.clusterbackupstatus_schema \
    as clusterbackupstatus_schema

DEFAULT_BACKUP_FILE_PATH = '/tmp/vdnet/backups/cluster/'

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id'
    }
    _client_class = issueclusterbackuprequest.IssueClusterBackupRequest
    _response_schema_class = clusterbackupstatus_schema.\
        ClusterBackupStatusSchema
    _schema_class = backuprequestschema.BackupRequestSchema
    _list_schema_class = clusterbackuplistresult_schema.\
        ClusterBackupListResultSchema

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        cls._client_class = listclusterbackups.ListClusterBackups
        return super(NSX70CRUDImpl, cls).read(client_obj, id_=id_)

    @classmethod
    def query(cls, client_obj, id_=None, **kwargs):
        cls._client_class = listclusterbackups.ListClusterBackups
        return super(NSX70CRUDImpl, cls).query(client_obj, **kwargs)

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        cls._client_class = listclusterbackups.ListClusterBackups
        return super(NSX70CRUDImpl, cls).delete(client_obj, id_=id_, **kwargs)