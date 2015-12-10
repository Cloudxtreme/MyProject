import vmware.nsx_api.manager.transportzone.transportzone as transportzone
import vmware.nsx_api.manager.transportzone.schema.transportzone_schema \
    as transportzone_schema
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
    _url_prefix = "/uiauto/v1"

    @classmethod
    def get_transport_nodes(cls, client_obj, get_transport_nodes=None):
        pylogger.info("%s.get_transport_nodes()" % cls.__name__)
