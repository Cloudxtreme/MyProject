import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.aggregation_interface as aggregation_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.heatmap.listtransportnodestatus as \
    listtransportnodestatus
import vmware.nsx_api.manager.clustermanagement.readclusternodestatus as \
    readclusternodestatus
import vmware.nsx_api.manager.appliancestats.listclusternodeinterfaces as \
    listclusternodeinterfaces

pylogger = global_config.pylogger


class NSX70AggregationImpl(aggregation_interface.AggregationInterface,
                           base_crud_impl.BaseCRUDImpl):

    @classmethod
    def get_aggregation_transportnode_status(cls, client_obj, **kwargs):
        """
        Get status summary of all transport nodes under MP.

        @type client_object: ManagerAPIClient
        @param client_object: Client object
        @rtype: dict
        @return: Dict having status details of all TNs.

        Endpoint:
        /aggregations/transport-node-status
        """
        attr_map = {'node_uuid': 'uuid',
                    'bfd_admin_down_count': 'admin_down_count',
                    'bfd_init_count': 'init_count',
                    'bfd_up_count': 'up_count',
                    'bfd_down_count': 'down_count'}
        client_class_obj = listtransportnodestatus.ListTransportNodeStatus(
            connection_object=client_obj.connection)
        status_schema_object = client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        mapped_dict = utilities.map_attributes(attr_map, status_schema_dict)
        result_dict = dict()
        result_dict['response'] = mapped_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def get_node_status(cls, client_object, node_id=None,
                        get_node_status=None):
        """
        Get control/manager cluster node status.

        @type client_object: ManagerAPIClient
        @param client_object: Client object
        @type node_id: string
        @param node_id: Control/Manager Cluster Node id
        @type get_node_status: List
        @param get_node_status: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having control/manager cluster node status

        Endpoint:
        /cluster/nodes/<node-id>/status
        """
        client_class_obj = \
            readclusternodestatus.ReadClusterNodeStatus(
                connection_object=client_object.connection,
                addclusternode_id=node_id)
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
    def get_node_interfaces(cls, client_object, node_id=None,
                            get_node_interfaces=None):
        """
        Get control/manager cluster node interface information.

        @type client_object: ManagerAPIClient
        @param client_object: Client object
        @type node_id: string
        @param node_id: Control/Manager Cluster Node id
        @type get_node_interfaces: List
        @param get_node_interfaces: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having control/manager cluster interface information

        Endpoint:
        /cluster/nodes/<node-id>/network/interfaces
        """
        client_class_obj = \
            listclusternodeinterfaces.ListClusterNodeInterfaces(
                connection_object=client_object.connection,
                addclusternode_id=node_id)
        status_schema_object = \
            client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        result_dict = dict()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
