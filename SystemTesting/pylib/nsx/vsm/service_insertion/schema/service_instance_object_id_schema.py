import base_schema

class ServiceInstanceObjectIdSchema(base_schema.BaseSchema):
    _schema_name = "serviceInstance"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstanceObjectIdSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceObjectIdSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)