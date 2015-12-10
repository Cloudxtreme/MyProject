import base_schema

class ServicesDepSchema(base_schema.BaseSchema):
    _schema_name = "serviceDeploymentConfig"

    def __init__(self, py_dict=None):
        """ Constructor to create ServicesDepSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServicesDepSchema, self).__init__()
        self.set_data_type('xml')
        self.serviceInstanceId = None
        self.ipPool = None
        self.dvPortGroup = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
