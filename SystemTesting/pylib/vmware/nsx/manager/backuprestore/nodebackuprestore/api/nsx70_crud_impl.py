import vmware.common.global_config as global_config
import schema.backup_request_schema as backuprequestschema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

import vmware.nsx_api.appliance.node.backupnode as backupnode
import vmware.nsx_api.appliance.node.listnodebackups as listnodebackups
import vmware.nsx_api.appliance.node.schema.nodebackupstatus_schema \
    as nodebackupstatus_schema
import vmware.nsx_api.appliance.node.schema.nodebackuplistresult_schema \
    as nodebackuplistresult_schema

DEFAULT_TECHSUPPORT_BUNDLE_PATH = '/tmp/vdnet/backups/node/'

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id'
    }
    _client_class = backupnode.BackupNode
    _response_schema_class = nodebackupstatus_schema.NodeBackupStatusSchema
    _schema_class = backuprequestschema.BackupRequestSchema
    _list_schema_class = nodebackuplistresult_schema.NodeBackupListResultSchema

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        cls._client_class = listnodebackups.ListNodeBackups
        return super(NSX70CRUDImpl, cls).read(client_obj, id_=id_)

    @classmethod
    def query(cls, client_obj, id_=None, **kwargs):
        cls._client_class = listnodebackups.ListNodeBackups
        return super(NSX70CRUDImpl, cls).query(client_obj, **kwargs)

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        cls._client_class = listnodebackups.ListNodeBackups
        return super(NSX70CRUDImpl, cls).delete(client_obj, id_=id_, **kwargs)