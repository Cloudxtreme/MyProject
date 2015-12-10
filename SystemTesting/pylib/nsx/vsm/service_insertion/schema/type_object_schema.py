import base_schema

class TypeObjectSchema(base_schema.BaseSchema):
    _schema_name = "type"

    def __init__(self, py_dict=None):
        """ Constructor to create TypeObjectSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(TypeObjectSchema, self).__init__()
        self.set_data_type('xml')
        self.typeName = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)