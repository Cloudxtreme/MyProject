import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx.manager.appliancemanagement.api.appmgmt_crud_impl \
    as appmgmt_crud
import vmware.nsx_api.appliance.node.schema.nodeuserproperties_schema \
    as nodeuserproperties_schema
import vmware.nsx_api.appliance.node.schema.\
    nodeuserpropertieslistresult_schema as nodeuserpropertieslistresult_schema
import vmware.nsx_api.appliance.node.updatenodeuser as updatenodeuser

pylogger = global_config.pylogger


class NSX70CRUDImpl(appmgmt_crud.AppMgmtCRUDImpl, base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = updatenodeuser.UpdateNodeUser
    _schema_class = nodeuserproperties_schema.NodeUserPropertiesSchema
    _list_schema_class = nodeuserpropertieslistresult_schema.\
        NodeUserPropertiesListResultSchema

    @classmethod
    def query(cls, client_obj, **kwargs):
        return cls.query_with_param_id(client_obj, **kwargs)

    @classmethod
    def update(cls, client_obj, id_=None, **kwargs):
        id_ = str(id_)
        return cls.update_with_param_id(client_obj, param_id=id_,
                                        **kwargs)