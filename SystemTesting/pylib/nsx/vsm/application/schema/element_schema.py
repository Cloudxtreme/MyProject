import base_schema

class ElementSchema(base_schema.BaseSchema):
    _schema_name = "element"

    def __init__(self, py_dict=None):
        """ Constructor to create ElementSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ElementSchema, self).__init__()
        self.set_data_type('xml')
        self.applicationProtocol = None
        self.value = None
        self.sourcePort = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)