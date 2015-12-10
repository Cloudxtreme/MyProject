import base_schema


class EdgeCentralizedApiCliSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "cliCmd"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeCentralizedApiCliSchema, self).__init__()
        self.set_data_type("xml")
        self.cmdStr = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


