import vmware.nsx_api.manager.certificatemanager.gettrustobjects\
    as gettrustobjects
import vmware.nsx_api.manager.certificatemanager.schema.\
    trustmanagementdata_schema as trustmanagementdata_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id'
    }

    _client_class = gettrustobjects.GetTrustObjects
    _schema_class = trustmanagementdata_schema.TrustManagementDataSchema
    _list_schema_class = trustmanagementdata_schema.TrustManagementDataSchema

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        cls.sanity_check()

        if kwargs['certificate_type'] is None:
            raise ValueError('certificate_type parameter is missing')

        url_parameters = {'type': kwargs['certificate_type']}

        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.delete(id_, url_parameters=url_parameters)

        result_dict = {
            'response_data': {
                'status_code': client_class_obj.last_calls_status_code}}
        return result_dict
