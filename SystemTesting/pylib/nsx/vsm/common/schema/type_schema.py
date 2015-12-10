import base_schema

class TypeSchema(base_schema.BaseSchema):
    _schema_name = "type"
    def __init__(self, py_dict=None):
        """ Constructor to create TypeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TypeSchema, self).__init__()
        self.set_data_type('xml')

        self.typeName = None
