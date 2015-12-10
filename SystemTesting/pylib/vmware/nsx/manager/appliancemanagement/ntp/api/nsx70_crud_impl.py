import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.updatenodentpservice \
    as updatenodentpservice
import vmware.nsx_api.appliance.node.schema.nodentpserviceproperties_schema \
    as nodentpserviceproperties_schema

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'service_name'
    }
    _client_class = updatenodentpservice.UpdateNodeNtpService
    _schema_class = nodentpserviceproperties_schema.\
        NodeNtpServicePropertiesSchema

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        return super(NSX70CRUDImpl, cls).read(client_obj, **kwargs)

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, **kwargs):
        return super(NSX70CRUDImpl, cls).update(client_obj, schema=schema,
                                                **kwargs)