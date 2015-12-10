import base_schema

class VXLANControllerSpecSchema(base_schema.BaseSchema):
    _schema_name = "controllerSpec"
    def __init__(self, py_dict = None):
        """ Constructor to create VXLANControllerSpecSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VXLANControllerSpecSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.ipPoolId = None
        self.hostId = None
        self.resourcePoolId = None
        self.datastoreId = None
        self.networkId = None
        self.deployType = None
        self.firstNodeOfCluster = None
        self.password = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

