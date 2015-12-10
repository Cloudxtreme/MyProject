import base_schema


class MulticastRangeSchema(base_schema.BaseSchema):
    _schema_name = "multicastRange"
    def __init__(self, py_dict=None):
        """ Constructor to create MulticastRangeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(MulticastRangeSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.desc = None
        self.begin = None
        self.end = None
        self.id = None
        self.isUniversal = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
