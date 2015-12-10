import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx.manager.appliancemanagement.api.appmgmt_crud_impl \
    as appmgmt_crud
import vmware.nsx_api.appliance.node.readnodeinterfacestatistics \
    as readnodeinterfacestatistics
import vmware.nsx_api.appliance.node.schema.nodeinterfaceproperties_schema \
    as nodeinterfaceproperties_schema
import vmware.nsx_api.appliance.node.schema.\
    nodeinterfacepropertieslistresult_schema \
    as nodeinterfacepropertieslistresult_schema
import vmware.nsx_api.appliance.node.updatenodeinterface as updatenodeinterface

pylogger = global_config.pylogger


class NSX70CRUDImpl(appmgmt_crud.AppMgmtCRUDImpl, base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = updatenodeinterface.UpdateNodeInterface
    _schema_class = nodeinterfaceproperties_schema.\
        NodeInterfacePropertiesSchema
    _list_schema_class = nodeinterfacepropertieslistresult_schema.\
        NodeInterfacePropertiesListResultSchema

    @classmethod
    def query(cls, client_obj, **kwargs):
        return cls.query_with_param_id(client_obj, **kwargs)

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        return cls.read_with_param_id(client_obj, param_id=id_,
                                      **kwargs)

    @classmethod
    def update(cls, client_obj, id_=None, **kwargs):
        return cls.update_with_param_id(client_obj, param_id=id_,
                                        **kwargs)

    @classmethod
    def get_interface_statistics(cls, client_object, interface_id=None,
                                 **kwargs):
        cls.sanity_check()
        client_class_obj = readnodeinterfacestatistics.\
            ReadNodeInterfaceStatistics(connection_object=client_object.
                                        connection,
                                        listnodeinterfaces_id=interface_id)
        schema_object = client_class_obj.read()
        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict