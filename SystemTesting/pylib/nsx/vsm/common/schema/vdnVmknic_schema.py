import base_schema

class VdnVmknicSchema(base_schema.BaseSchema):
    _schema_name = "vdnVmknic"
    def __init__(self, py_dict=None):
        """ Constructor to create VdnVmknicSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VdnVmknicSchema, self).__init__()
        self.ipAddress = None
        self.dhcp = None
        self.validIp = None
        self.deviceId = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
