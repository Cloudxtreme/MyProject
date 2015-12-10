import vmware.nsx_api.manager.transportzone.transportzone as transportzone
import vmware.nsx_api.manager.transportnode.transportnode as transportnode
import vmware.nsx_api.manager.transportzone.schema.transportzonelistresult_schema as transportzonelistresult_schema  # noqa
import vmware.nsx_api.manager.transportzone.schema.transportzone_schema as transportzone_schema  # noqa
import vmware.nsx_api.manager.transportnode.schema.transportnodelistresult_schema as transportnodelistresult_schema  # noqa
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'switch_name': 'host_switch_name',
        'summary': 'description',
        'transport_zone_type': 'transport_type'
    }

    _client_class = transportzone.TransportZone
    _schema_class = transportzone_schema.TransportZoneSchema
    _list_schema_class = transportzonelistresult_schema.\
        TransportZoneListResultSchema

    @classmethod
    def get_transport_nodes(cls, client_obj, get_transport_nodes=None):
        pylogger.info("%s.get_transport_nodes()" % cls.__name__)

        # get current transport zone id
        transport_zone_id = client_obj.id_

        _tn_client_class = transportnode.TransportNode
        _tn_list_result_schema_class = transportnodelistresult_schema.\
            TransportNodeListResultSchema

        tn_client_class_obj = _tn_client_class(
            connection_object=client_obj.connection)
        #
        # Creating tn_list_schema_object of client and
        # sending it to query method. Query method will
        # fill this tn_list_schema_object and return it back
        #
        tn_list_result_schema_object = _tn_list_result_schema_class()
        tn_list_result_schema_object = tn_client_class_obj.\
            query(tn_list_result_schema_object)

        tn_list = []
        py_dict = {}
        tn_list_schema_objects = tn_list_result_schema_object.results
        for tn in tn_list_schema_objects:
            vtep_list_schema_objects = tn.transport_zone_endpoints
            for vtep in vtep_list_schema_objects:
                tz_id = vtep.transport_zone_id
                # if current vtep attribute transport_zone_id equals tz id
                # then current transport node can be seen as within this tz
                if transport_zone_id == tz_id:
                    # append transport node id
                    tn_list.append({'node_id': str(tn.id)})

        py_dict = {'table': tn_list}
        return py_dict
