import base_schema


class ApplianceSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "appliance"
    def __init__(self, py_dict=None):
        """ Constructor to create ApplianceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ApplianceSchema, self).__init__()
        self.set_data_type("xml")
        self.resourcePoolId = None
        self.resourcePoolName = None
        self.datastoreId = None
        self.datastoreName = None
        self.hostId = None
        self.hostName = None
        self.vmFolderId = None
        self.vmFolderName = None
        self.vmHostname = None
        self.vmName = None
        self.highAvailabilityIndex = None
        self.vcUuid = None
        self.vmId = None
        self.deployed = None
        self.edgeId = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)