import base_schema

class NodeConfigSchema(base_schema.BaseSchema):
    _schema_name = "nodeconfig"

    def __init__(self, py_dict=None):

        super(NodeConfigSchema, self).__init__()
        self.port_number = None
        self.display_name = None
        self.host_address = None
        self.certificate = None
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
