import base_schema

class ServiceManagerSchema(base_schema.BaseSchema):
    _schema_name = "serviceManager"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceManagerSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceManagerSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.revision = None
        self.objectTypeName = None
        self.vendorName = None
        self.vendorId = None
        self.thumbprint = None
        self.login = None
        self.password = None
        self.verifyPassword = None
        self.url = None
        self.restUrl = None
        self.status = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)