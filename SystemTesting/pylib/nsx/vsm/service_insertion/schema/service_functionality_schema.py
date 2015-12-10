import base_schema

class ServiceFunctionalitySchema(base_schema.BaseSchema):
    _schema_name = "functionality"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceFunctionalitySchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceFunctionalitySchema, self).__init__()
        self.set_data_type('xml')
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)