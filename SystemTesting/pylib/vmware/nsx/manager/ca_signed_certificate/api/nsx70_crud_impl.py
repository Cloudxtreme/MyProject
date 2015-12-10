import vmware.nsx_api.manager.certificatemanager.importcertificate\
    as importcertificate
import vmware.nsx_api.manager.certificatemanager.addcertificate\
    as addcertificate
import vmware.nsx_api.manager.certificatemanager.schema.certificate_schema\
    as certificate_schema
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

    _client_class = importcertificate.ImportCertificate
    _schema_class = certificate_schema.CertificateSchema

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()

        pylogger.info("%s.create(schema=%s, kwargs=%s)" %
                      (cls.__name__, schema, kwargs))

        payload = utilities.map_attributes(cls._attribute_map, schema)

        if kwargs['csr_id'] is None:
            raise ValueError('csr_id parameter is missing')

        csr_id = kwargs['csr_id']

        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            generatecsr_id=csr_id)

        schema_object = cls._schema_class(payload)
        schema_object = client_class_obj.create(
            schema_object)

        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        cls._client_class = addcertificate.AddCertificate
        return super(NSX70CRUDImpl, cls).delete(client_obj, id_=id_, **kwargs)
