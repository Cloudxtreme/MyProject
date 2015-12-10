import base_schema

class ServiceTransportSchema(base_schema.BaseSchema):
    _schema_name = "transport"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceTransportSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceTransportSchema, self).__init__()
        self.set_data_type('xml')
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)