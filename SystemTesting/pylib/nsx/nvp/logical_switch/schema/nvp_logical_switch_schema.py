import base_schema
import nvp_tag_schema
import nvp_transport_zone_binding_schema

class LogicalSwitch(base_schema.BaseSchema):
    _schema_name = "logicalSwitch"

    def __init__(self, py_dict=None):
        super(LogicalSwitch, self).__init__()
        self.display_name = None
        self.transport_zones = [nvp_transport_zone_binding_schema.TransportZoneBinding()]
        self.uuid = None
        self.transport_type = None
        self.replication_mode = None
        self.tags = [nvp_tag_schema.Tag()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def add_transport_zone_binding(self, transport_zone):
        self.transport_zones.append(transport_zone)

    def add_tag(self, tag):
        self.tags.append(tag)

if __name__=='__main__':
    pass
