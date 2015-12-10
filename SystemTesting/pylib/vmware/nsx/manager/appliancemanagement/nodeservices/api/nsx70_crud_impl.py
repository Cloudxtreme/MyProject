import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx.manager.appliancemanagement.api.appmgmt_crud_impl \
    as appmgmt_crud
import vmware.nsx_api.appliance.node.postnodeserviceaction as \
    postnodeserviceaction
import vmware.nsx_api.appliance.node.readnodeservicestatus as \
    readnodeservicestatus
import vmware.nsx_api.appliance.node.schema.\
    nodeservicestatusproperties_schema \
    as nodeservicestatusproperties_schema
import vmware.nsx_api.appliance.node.schema.\
    nodeservicepropertieslistresult_schema \
    as nodeservicepropertieslistresult_schema


pylogger = global_config.pylogger


class NSX70CRUDImpl(appmgmt_crud.AppMgmtCRUDImpl, base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = postnodeserviceaction.PostNodeServiceAction
    _schema_class = nodeservicestatusproperties_schema.\
        NodeServiceStatusPropertiesSchema
    _list_schema_class = nodeservicepropertieslistresult_schema.\
        NodeServicePropertiesListResultSchema

    @classmethod
    def query(cls, client_obj, **kwargs):
        return cls.query_with_param_id(client_obj, **kwargs)

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        cls._client_class = readnodeservicestatus.ReadNodeServiceStatus
        return cls.read_with_param_id(client_obj, param_id=id_)