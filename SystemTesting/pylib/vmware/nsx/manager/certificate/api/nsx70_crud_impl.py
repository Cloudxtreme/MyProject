import vmware.nsx_api.manager.certificatemanager.addcertificate\
    as addcertificate
import vmware.nsx_api.manager.certificatemanager.schema.certificate_schema\
    as certificate_schema
import vmware.nsx_api.manager.certificatemanager.schema.certificatelist_schema\
    as certificatelist_schema
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'expiry_date': 'not_after',
        'public_key_algorithm': 'public_key_algo',
        'dsa_public_key_base': 'dsa_public_key_g',
        'dsa_public_key_prime': 'dsa_public_key_p',
        'dsa_public_key_subprime': 'dsa_public_key_q'
    }

    _client_class = addcertificate.AddCertificate
    _schema_class = certificate_schema.CertificateSchema
    _list_schema_class = certificatelist_schema.CertificateListSchema
    _response_schema_class = certificatelist_schema.CertificateListSchema

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        cls.sanity_check()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.set_endpoints("/trust-management/certificates")
        client_class_obj.delete(id_)

        result_dict = {
            'response_data': {
                'status_code': client_class_obj.last_calls_status_code}}
        return result_dict

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        cls._response_schema_class = certificate_schema.CertificateSchema
        cls.sanity_check()
        cls.assign_response_schema_class()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)
        client_class_obj.set_endpoints("/trust-management/certificates")
        schema_object = client_class_obj.read(id_)

        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def query(cls, client_obj, **kwargs):
        cls.sanity_check()
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)

        pylogger.info("%s.query" % cls.__name__)

        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.set_endpoints("/trust-management/certificates")

        list_schema_object = cls._list_schema_class()
        list_schema_object = client_class_obj.query(list_schema_object)

        list_schema_dict = list_schema_object.get_py_dict_from_object()

        verification_form = utilities.map_attributes(
            cls._attribute_map, list_schema_dict, reverse_attribute_map=True)

        result_dict = dict()
        result_dict['response'] = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
