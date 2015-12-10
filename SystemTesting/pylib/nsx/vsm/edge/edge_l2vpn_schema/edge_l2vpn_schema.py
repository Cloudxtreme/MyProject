import base_schema
from logging_schema import LoggingSchema

class L2VPNSchema(base_schema.BaseSchema):
    _schema_name = "l2Vpn"
    def __init__(self, py_dict=None):
        """ Constructor to create L2VPNSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(L2VPNSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.logging = LoggingSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)