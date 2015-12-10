import base_schema


class MACNodeSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "macNode"
    def __init__(self, py_dict=None):
        """ Constructor to create MACNodeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(MACNodeSchema, self).__init__()
        self.set_data_type('xml')
        self.macAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


