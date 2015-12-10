import base_schema

class ServiceAttributeSchema(base_schema.BaseSchema):
    _schema_name = "attribute"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceAttributeSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceAttributeSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None # check if it works for both post and get calls
        self.revision = None # check if it works for both post and get calls
        self.key = None
        self.name = None
        self.value = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)