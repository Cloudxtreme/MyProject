import base_schema

class ExtendedAttributeSchema(base_schema.BaseSchema):
    _schema_name = "extendedattribute"

    def __init__(self, py_dict=None):
        """ Constructor to create ExtendedAttributeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ExtendedAttributeSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.value = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)