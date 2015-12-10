import base_schema

class TransportZoneBindingSchema(base_schema.BaseSchema):
    _schema_name = "transportzonebinding"

    def __init__(self, py_dict=None):
        """ Constructor to create TransportZoneBindingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TransportZoneBindingSchema, self).__init__()
        self.transport_zone_config = None
        self.transport_zone_id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)