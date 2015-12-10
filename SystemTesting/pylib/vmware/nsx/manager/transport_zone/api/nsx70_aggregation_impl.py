import vmware.common.global_config as global_config
import vmware.interfaces.aggregation_interface as aggregation_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.heatmap.getheatmaptransportzonestatus as getheatmaptransportzonestatus  # noqa


pylogger = global_config.pylogger


class NSX70AggregationImpl(aggregation_interface.AggregationInterface,
                           base_crud_impl.BaseCRUDImpl):

    @classmethod
    def get_aggregation_status(cls, client_obj, get_aggregation_status=None):
        """
        Returns the high-level summary of a transport zone showing the number
        of up/degraded/down/unknown transport nodes.

        @type client_object: TransportZoneAPIClient
        @param client_object: Client object
        @rtype: dict
        @return: Dict having number of up/degraded/down/unknown transport nodes

        Endpoint:
        /aggregations/transport-zones/<zone-id>/status

        Sample return value result_dict['response']:
        {
          "down_count" : 0,
          "unknown_count" : 2,
          "up_count" : 0,
          "degraded_count" : 0
        }
        """
        zone_id = client_obj.id_
        # TODO(gangarm): Check if we can use a better name in product sdk for
        # param_1_id, which is essentially zone id.
        client_class_obj = \
            getheatmaptransportzonestatus.GetHeatmapTransportZoneStatus(
                connection_object=client_obj.connection, param_1_id=zone_id)
        status_schema_object = client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        result_dict = dict()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
