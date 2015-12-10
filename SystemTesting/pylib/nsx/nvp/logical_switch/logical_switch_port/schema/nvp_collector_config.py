import base_schema

class CollectorConfigSchema(base_schema.BaseSchema):
    _schema_name = "collectorconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create CollectorConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(CollectorConfigSchema, self).__init__()
        self.ip_address = None
        self.mirror_key = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
