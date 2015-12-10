import base_schema


class BridgeSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "bridge"
    def __init__(self, py_dict=None):
        """ Constructor to create BridgeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(BridgeSchema, self).__init__()
        self.type = None
        self.name = None
        self.bridgeId = None
        self.virtualWire = None
        self.dvportGroup = None
        self.set_data_type("xml")

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
