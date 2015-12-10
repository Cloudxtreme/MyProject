import base_schema
from authentication_schema import AuthenticationSchema


class OSPFAreaSchema(base_schema.BaseSchema):
    _schema_name = "ospfArea"

    def __init__(self, py_dict=None):
        """ Constructor to create OspfAreaSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(OSPFAreaSchema, self).__init__()
        self.set_data_type("xml")
        self.areaId = None
        self.type = None
        self.authentication = AuthenticationSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
