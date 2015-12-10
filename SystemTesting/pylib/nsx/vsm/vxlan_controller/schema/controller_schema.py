import base_schema

class controllerSchema(base_schema.BaseSchema):
    _schema_name = "controller"
    """"""
    def __init__(self, py_dict = None):
        """ Constructor to create controllerSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(controllerSchema, self).__init__()
        self.set_data_type('xml')
        self.revision = None
        self.name = None
        self.clientHandle = None
        self.id = None
        self.ipAddress = None
        self.status = None
        self.version = None
        self.upgradeAvailable = None
        self.upgradeStatus = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

