import vmware.common.global_config as global_config
import vmware.interfaces.aggregation_interface as aggregation_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.fabricnode.readnodestatus as readnodestatus
import vmware.nsx_api.manager.appliancestats.listfabricnodeinterfaces as \
    listfabricnodeinterfaces

pylogger = global_config.pylogger


class NSX70AggregationImpl(aggregation_interface.AggregationInterface,
                           base_crud_impl.BaseCRUDImpl):

    @classmethod
    def get_node_status(cls, client_object, get_node_status=None):
        """
        Get fabric host node status.

        @type client_object: HostNodeAPIClient
        @param client_object: Client object
        @type get_node_status: List
        @param get_node_status: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having fabric host node status

        Endpoint:
        /fabric/nodes/<node-id>/status
        """
        client_class_obj = \
            readnodestatus.ReadNodeStatus(
                connection_object=client_object.connection,
                addnode_id=client_object.id_)
        status_schema_object = \
            client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        result_dict = dict()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def get_node_interfaces(cls, client_object, get_node_interfaces=None):
        """
        Get fabric host node interface information.

        @type client_object: HostNodeAPIClient
        @param client_object: Client object
        @type get_node_interfaces: List
        @param get_node_interfaces: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having fabric host node interface information

        Endpoint:
        /fabric/nodes/<node-id>/network/interfaces
        """
        client_class_obj = \
            listfabricnodeinterfaces.ListFabricNodeInterfaces(
                connection_object=client_object.connection,
                addnode_id=client_object.id_)
        status_schema_object = \
            client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        result_dict = dict()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
