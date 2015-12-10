import os

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.snapshot_interface as snapshot_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import schema.backup_request_schema as backuprequestschema
import schema.restore_request_schema as restorerequestschema

import vmware.nsx_api.manager.clusterbackup.clusterrestore as clusterrestore
import vmware.nsx_api.manager.clusterbackup.getclusterbackupfile \
    as getclusterbackupfile
import vmware.nsx_api.manager.clusterbackup.issueclusterbackuprequest \
    as issueclusterbackuprequest
import vmware.nsx_api.manager.clusterbackup.purgeclusterbackups \
    as purgeclusterbackups
import vmware.nsx_api.manager.clusterbackup.schema.clusterbackupstatus_schema \
    as clusterbackupstatus_schema

DEFAULT_BACKUP_FILE_PATH = '/tmp/vdnet/backups/cluster/'

pylogger = global_config.pylogger


class NSX70SnapshotImpl(snapshot_interface.SnapshotInterface,
                        base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id'
    }
    _client_class = issueclusterbackuprequest.IssueClusterBackupRequest
    _response_schema_class = clusterbackupstatus_schema.\
        ClusterBackupStatusSchema
    _schema_class = backuprequestschema.BackupRequestSchema

    @classmethod
    def restore(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()
        cls._client_class = clusterrestore.ClusterRestore
        cls._schema_class = restorerequestschema.RestoreRequestSchema
        kwargs.update({'filename': 'cluster_backup.zip'})
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
    def download(cls, client_obj, schema=None, **kwargs):
        cls._client_class = getclusterbackupfile.GetClusterBackupFile
        file_path = DEFAULT_BACKUP_FILE_PATH + client_obj.id_
        cls.assign_response_schema_class()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection, param_1_id=client_obj.id_)
        cls._get_backup_file(client_class_obj.read(), file_path)
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def _get_backup_file(cls, file_content, file_path):
        try:
            if not os.path.exists(DEFAULT_BACKUP_FILE_PATH):
                os.makedirs(DEFAULT_BACKUP_FILE_PATH)
            filename = file_path
            pylogger.info("Saving Cluster Level Backup File as: %s" % filename)
            f = open(filename, 'w')
            f.write(file_content)
            f.close()
        except Exception:
            raise Exception("Failed to Save Cluster Backup File")
        return True, filename

    @classmethod
    def purge(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()
        cls._client_class = purgeclusterbackups.PurgeClusterBackups
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