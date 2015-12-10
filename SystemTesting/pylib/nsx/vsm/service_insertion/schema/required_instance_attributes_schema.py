import base_schema

class RequiredInstanceAttributesSchema(base_schema.BaseSchema):
    _schema_name = "attribute"

    def __init__(self, py_dict=None):
        """ Constructor to create RequiredInstanceAttributesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RequiredInstanceAttributesSchema, self).__init__()
        self.set_data_type('xml')
        self.key = None
        self.name = None
        self.value = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
