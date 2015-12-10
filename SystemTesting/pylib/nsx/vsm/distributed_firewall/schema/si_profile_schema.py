import base_schema

class SiProfileSchema(base_schema.BaseSchema):
    _schema_name = "siProfile"

    def __init__(self, py_dict=None):
        """ Constructor to create SiProfileSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(SiProfileSchema, self).__init__()
        self.set_data_type("xml")
        self.objectId = None
        self.revision = None
        self.name = None
        self.description = None
        self.clientHandle = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
