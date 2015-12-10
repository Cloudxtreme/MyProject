import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.aggregation_interface as aggregation_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.heatmap.gettransportnodestatus as gettransportnodestatus  # noqa


pylogger = global_config.pylogger


class NSX70AggregationImpl(aggregation_interface.AggregationInterface,
                           base_crud_impl.BaseCRUDImpl):

    @classmethod
    def get_aggregation_status(cls, client_obj, get_aggregation_status=None):
        """
        Get status summary of given transport node.

        @type client_object: TransportNodeAPIClient
        @param client_object: Client object
        @rtype: dict
        @return: Dict having status details of TN.

        Endpoint:
        /aggregations/<node-id>/transport-node-status
        """
        attr_map = {'node_uuid': 'uuid',
                    'bfd_admin_down_count': 'admin_down_count',
                    'bfd_init_count': 'init_count',
                    'bfd_up_count': 'up_count',
                    'bfd_down_count': 'down_count'}
        node_id = client_obj.id_
        # TODO(gangarm): Check if we can use a better name in product sdk for
        # param_1_id, which is essentially node id.
        client_class_obj = gettransportnodestatus.GetTransportNodeStatus(
            connection_object=client_obj.connection, param_1_id=node_id)
        status_schema_object = client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        mapped_dict = utilities.map_attributes(attr_map, status_schema_dict)
        result_dict = dict()
        result_dict['response'] = mapped_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
