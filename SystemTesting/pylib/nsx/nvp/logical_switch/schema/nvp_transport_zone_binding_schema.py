import base_schema

class TransportZoneBinding(base_schema.BaseSchema):
    _schema_type = "transportZoneBinding"

    def __init__(self, py_dict=None):
        super(TransportZoneBinding, self).__init__()
        self.transport_type = None
        self.zone_uuid = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
