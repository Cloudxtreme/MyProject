import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.updatenodenameservers \
    as updatenodenameservers
import vmware.nsx_api.appliance.node.schema.nodenameserversproperties_schema \
    as nodenameserversproperties_schema

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'name': 'name_servers',
    }
    _client_class = updatenodenameservers.UpdateNodeNameServers
    _schema_class = nodenameserversproperties_schema.\
        NodeNameServersPropertiesSchema

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        return super(NSX70CRUDImpl, cls).read(client_obj, **kwargs)

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, **kwargs):
        return super(NSX70CRUDImpl, cls).update(client_obj, schema=schema,
                                                **kwargs)