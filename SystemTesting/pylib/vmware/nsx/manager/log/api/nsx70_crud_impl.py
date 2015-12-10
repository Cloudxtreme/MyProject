import os
import time
import vmware.nsx_api.appliance.node.listnodelogs as \
    listnodelogs
import vmware.nsx_api.appliance.node.readnodelogdata as \
    readnodelogdata
import vmware.nsx_api.appliance.node.schema.nodelogpropertieslistresult_schema\
    as nodelogpropertieslistresult_schema
import vmware.nsx_api.appliance.node.schema.nodelogproperties_schema \
    as nodelogproperties_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

DEFAULT_LOG_PATH = '/tmp/vdnet/nsxlogs/'

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    #  Attribute map
    _attribute_map = {
        'id_': 'log_name',
    }

    _client_class = listnodelogs.ListNodeLogs
    _schema_class = nodelogproperties_schema.NodeLogPropertiesSchema
    _list_schema_class = nodelogpropertieslistresult_schema\
        .NodeLogPropertiesListResultSchema

    @classmethod
    def check_log_file(cls, client_obj, **kwargs):
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['result'] = os.path.isfile(client_obj.id_)
        result_dict['response_data']['status_code'] = 200
        return result_dict

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        log_type = schema.get('name')
        cls._client_class = readnodelogdata.ReadNodeLogData
        cls.assign_response_schema_class()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection, listnodelogs_id=log_type)
        result, filename = cls._create_nsx_log(
            log_type, client_class_obj.read())
        schema_dict = {'id_': filename}
        result_dict = schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def _create_nsx_log(cls, log_type, file_content):
        try:
            if not os.path.exists(DEFAULT_LOG_PATH):
                os.makedirs(DEFAULT_LOG_PATH)
            filename = DEFAULT_LOG_PATH + log_type + '-' + \
                time.strftime("%Y%m%d-%H%M%S")
            pylogger.info("Saving NSX Logs in : %s" % filename)
            f = open(filename, 'w')
            f.write(file_content)
            f.close()
        except Exception:
            raise Exception("Failed to Save NSX Logs :" + log_type)
        return True, filename