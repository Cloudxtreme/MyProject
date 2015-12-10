import base_schema

class ServiceManagerObjectSchema(base_schema.BaseSchema):
    _schema_name = "serviceManager"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceManagerObjectSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceManagerObjectSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)