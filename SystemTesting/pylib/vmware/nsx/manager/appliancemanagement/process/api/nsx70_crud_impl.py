import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.schema.\
    nodeprocesspropertieslistresult_schema \
    as nodeprocesspropertieslistresult_schema
import vmware.nsx_api.appliance.node.listnodeprocesses as listnodeprocesses

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = listnodeprocesses.ListNodeProcesses
    _schema_class = nodeprocesspropertieslistresult_schema.\
        NodeProcessPropertiesListResultSchema
    _list_schema_class = nodeprocesspropertieslistresult_schema.\
        NodeProcessPropertiesListResultSchema