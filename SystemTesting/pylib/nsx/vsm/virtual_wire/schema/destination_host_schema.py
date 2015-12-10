import base_schema

class DestinationHostSchema(base_schema.BaseSchema):
    _schema_name = "destinationHost"
    def __init__(self, py_dict=None):
        """ Constructor to create DestinationHostSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DestinationHostSchema, self).__init__()
        self.set_data_type('xml')
        self.hostId = None
        self.switchId = None
        self.vlanId = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

