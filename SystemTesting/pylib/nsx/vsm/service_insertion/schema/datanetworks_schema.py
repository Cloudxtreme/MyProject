import base_schema

class DatanetworksSchema(base_schema.BaseSchema):
    _schema_name = "dataNetworks"

    def __init__(self, py_dict=None):
        """ Constructor to create DatanetworksSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DatanetworksSchema, self).__init__()
        self.set_data_type('xml')
        self.string = [str()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
