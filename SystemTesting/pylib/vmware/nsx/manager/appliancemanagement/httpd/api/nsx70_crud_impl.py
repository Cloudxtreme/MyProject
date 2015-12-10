import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.schema.nodehttpdserviceproperties_schema \
    as nodehttpdserviceproperties_schema
import vmware.nsx_api.appliance.node.readnodehttpdservice \
    as readnodehttpdservice

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = readnodehttpdservice.ReadNodeHttpdService
    _schema_class = nodehttpdserviceproperties_schema.\
        NodeHttpdServicePropertiesSchema

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        return super(NSX70CRUDImpl, cls).read(client_obj, **kwargs)

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, **kwargs):
        cert_id = schema.pop('id_')
        kwargs = {'query_params': {'action': 'apply_certificate',
                  'certificate_id': cert_id}}
        return super(NSX70CRUDImpl, cls).create(client_obj, **kwargs)