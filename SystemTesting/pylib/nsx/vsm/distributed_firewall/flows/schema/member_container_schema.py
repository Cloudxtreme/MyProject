import base_schema

class MemberContainerSchema(base_schema.BaseSchema):
    _schema_name = "memberContainer"

    def __init__(self, py_dict=None):
        """ Constructor to create SourceContainerSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(MemberContainerSchema, self).__init__()
        self.set_data_type("xml")
        self.type = None
        self.name = None
        self.id = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
