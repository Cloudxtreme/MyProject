import base_schema


class ServiceGroupMemberSchema(base_schema.BaseSchema):
    _schema_name = "servicegroupmember"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceGroupSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ServiceGroupMemberSchema, self).__init__()
        self._member_id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)