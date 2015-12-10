import base_schema
from bridge_schema import BridgeSchema


class BridgesSchema(base_schema.BaseSchema):
    _schema_name = "bridges"
    def __init__(self, py_dict=None):
        """ Constructor to create BridgesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(BridgesSchema, self).__init__()
        self.enabled = None
        self.version = None
        self.bridges = [BridgeSchema()]
        self.set_data_type("xml")

        if py_dict != None:
           self.get_object_from_py_dict(py_dict)
