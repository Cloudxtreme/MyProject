import base_schema


class AuthenticationSchema(base_schema.BaseSchema):
    _schema_name = "authentication"

    def __init__(self, py_dict=None):
        """ Constructor to create AuthenticationSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(AuthenticationSchema, self).__init__()
        self.set_data_type("xml")
        self.type = None
        self.value = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
