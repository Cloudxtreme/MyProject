import vmware.common.global_config as global_config
import vmware.nsx_api.appliance.node.postnodeserviceaction as \
    postnodeserviceaction
import vmware.nsx_api.appliance.node.readnodeservicestatus as \
    readnodeservicestatus
import vmware.nsx_api.appliance.node.schema.\
    nodeservicestatusproperties_schema as \
    nodeservicestatusproperties_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx.manager.appliancemanagement.api.appmgmt_crud_impl \
    as appmgmt_crud

pylogger = global_config.pylogger


class NSX70ServiceImpl(appmgmt_crud.AppMgmtCRUDImpl,
                       base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = readnodeservicestatus.ReadNodeServiceStatus
    _schema_class = nodeservicestatusproperties_schema.\
        NodeServiceStatusPropertiesSchema

    @classmethod
    def configure_service_state(cls, client_object, service_name=None,
                                state=None, **kwargs):
        if state == 'start':
            cls._set_service_state(client_object, service_name,
                                   url_parameters={'action': 'start'})
        elif state == 'stop':
            cls._set_service_state(client_object, service_name,
                                   url_parameters={'action': 'stop'})
        elif state == 'restart':
            cls._set_service_state(client_object, service_name,
                                   url_parameters={'action': 'restart'})
        else:
            raise ValueError("Received incorrect service state")

    @classmethod
    def _set_service_state(cls, client_object, service_name, url_parameters):
        client_class_obj = postnodeserviceaction.PostNodeServiceAction(
            connection_object=client_object.connection,
            param_1_id=service_name)
        client_class_obj.create(schema_object=None,
                                url_parameters=url_parameters)
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = \
            client_class_obj.last_calls_status_code
        return result_dict
