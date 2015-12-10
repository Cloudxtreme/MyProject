import base_schema


class ApplicationGroupMemberSchema(base_schema.BaseSchema):
    _schema_name = "member"

    def __init__(self, py_dict=None):
        """ Constructor to create ApplicationGroupMemberSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ApplicationGroupMemberSchema, self).__init__()
        self._member_id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
