import vmware.nsx_api.manager.certificatemanager.generatecsr as generatecsr
import vmware.nsx_api.manager.certificatemanager.getcsrpem as getcsrpem
import vmware.nsx_api.manager.certificatemanager.schema.csr_schema\
    as csr_schema
import vmware.nsx_api.manager.certificatemanager.schema.csrlist_schema\
    as csrlist_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id'
    }

    _client_class = generatecsr.GenerateCsr
    _schema_class = csr_schema.CsrSchema
    _list_schema_class = csrlist_schema.CsrListSchema

    @classmethod
    def download(cls, client_obj, csr_id=None, **kwargs):
        cls._client_class = getcsrpem.GetCsrPem
        cls.sanity_check()
        cls.assign_response_schema_class()

        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix,
            generatecsr_id=csr_id)

        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)
        pem_data = client_class_obj.query()

        result_dict = dict()
        result_dict['pem_data'] = pem_data
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] =\
            client_class_obj.last_calls_status_code
        return result_dict
