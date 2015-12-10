import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.snapshot_interface as snapshot_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import schema.backup_request_schema as backuprequestschema
import schema.restore_request_schema as restorerequestschema

import vmware.nsx_api.appliance.node.backupnode as backupnode
import vmware.nsx_api.appliance.node.purgenodebackups as purgenodebackups
import vmware.nsx_api.appliance.node.restorenode as restorenode
import vmware.nsx_api.appliance.node.schema.nodebackupstatus_schema \
    as nodebackupstatus_schema

DEFAULT_TECHSUPPORT_BUNDLE_PATH = '/tmp/vdnet/backups/node/'

pylogger = global_config.pylogger


class NSX70SnapshotImpl(snapshot_interface.SnapshotInterface,
                        base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id'
    }
    _client_class = backupnode.BackupNode
    _response_schema_class = nodebackupstatus_schema.NodeBackupStatusSchema
    _schema_class = backuprequestschema.BackupRequestSchema

    @classmethod
    def restore(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()
        cls._client_class = restorenode.RestoreNode
        cls._schema_class = restorerequestschema.RestoreRequestSchema
        kwargs.update({'filename': client_obj.id_})
        schema = kwargs
        pylogger.info("%s.create(schema=%s, kwargs=%s)" %
                      (cls.__name__, schema, kwargs))
        client_class_obj = cls.get_sdk_client_object(
            client_obj)
        payload = utilities.map_attributes(cls._attribute_map, schema)
        pylogger.debug("Payload: %s" % payload)
        schema_class_obj = cls._schema_class(payload)
        client_class_obj.create(schema_object=schema_class_obj)
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = \
            client_class_obj.last_calls_status_code
        return result_dict

    @classmethod
    def purge(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()
        cls._client_class = purgenodebackups.PurgeNodeBackups
        cls._schema_class = restorerequestschema.RestoreRequestSchema
        pylogger.info("%s.create(schema=%s, kwargs=%s)" %
                      (cls.__name__, schema, kwargs))
        client_class_obj = cls.get_sdk_client_object(
            client_obj)
        payload = utilities.map_attributes(cls._attribute_map, schema)
        pylogger.debug("Payload: %s" % payload)
        schema_class_obj = cls._schema_class(payload)
        client_class_obj.create(schema_object=schema_class_obj)
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = \
            client_class_obj.last_calls_status_code
        return result_dict