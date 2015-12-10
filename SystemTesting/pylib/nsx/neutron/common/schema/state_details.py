import base_schema

class StateDetailsSchema(base_schema.BaseSchema):
    _schema_name = "tag"

    def __init__(self, py_dict=None):
        """ Constructor to create details in State object

        @param py_dict : python dictionary to construct this object
        """
        super(StateDetailsSchema, self).__init__()
        self.sub_system_address = None
        self.sub_system_id = None
        self.state = None
        self.failure_message = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

