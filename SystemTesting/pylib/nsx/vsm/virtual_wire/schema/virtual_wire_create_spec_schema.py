import base_schema


class VirtualWireCreateSpecSchema(base_schema.BaseSchema):
    _schema_name = 'virtualWireCreateSpec'
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireCreateSpecSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VirtualWireCreateSpecSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = "vwire test"
        self.tenantId = None
        self.controlPlaneMode = None
        self.id = None
        self.guestVlanAllowed = None
        self.isUniversal = None
        self.universalRevision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
