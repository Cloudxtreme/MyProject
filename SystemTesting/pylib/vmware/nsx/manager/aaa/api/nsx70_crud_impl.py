import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

import vmware.nsx_api.appliance.common.\
    tacacsplusaaaprovidergroupproperties_schema as tacacs_schema
import vmware.nsx_api.appliance.node.schema.aaaprovidersproperties_schema\
    as aaaprovider_schema
import vmware.nsx_api.appliance.node.updateaaaprovidersproperties\
    as aaaprovider

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id'
    }

    _client_class = aaaprovider.UpdateAAAProvidersProperties
    _schema_class = tacacs_schema.\
        TacacsPlusAAAProviderGroupPropertiesSchema
    _list_schema_class = aaaprovider_schema.\
        AAAProvidersPropertiesSchema

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, parent_id=None,
               merge=None, **kwargs):
        cls._schema_class = aaaprovider_schema.AAAProvidersPropertiesSchema
        id_ = None
        merge = True

        return super(NSX70CRUDImpl, cls).update(
            client_obj, id_, schema, parent_id, merge, **kwargs)