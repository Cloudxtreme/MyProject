import base_schema


class OSPFInterfaceSchema(base_schema.BaseSchema):
    _schema_name = "ospfInterface"

    def __init__(self, py_dict=None):
        """ Constructor to create OspfInterfaceSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(OSPFInterfaceSchema, self).__init__()
        self.set_data_type("xml")
        self.vnic = None
        self.areaId = None
        self.helloInterval = None
        self.priority = None
        self.cost = None
        self.deadInterval = None
        self.mtuIgnore = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
