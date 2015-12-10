import base_schema


class OspfCliAreaSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "areas"
    def __init__(self, py_dict=None):
        """ Constructor to create OspfAreaSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(OspfCliAreaSchema, self).__init__()
        self.areaId = None
        self.authenticationType = None
        self.authenticationSecret = None
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

