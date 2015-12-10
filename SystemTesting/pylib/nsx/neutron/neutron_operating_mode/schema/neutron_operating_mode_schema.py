import base_schema
from resource_link_schema import ResourceLinkSchema

class OperatingModeSchema(base_schema.BaseSchema):
    _schema_name = "operatingmode"

    def __init__(self, py_dict=None):
        """ Constructor to create operating mode object

        @param py_dict : python dictionary to construct this object
        """
        super(OperatingModeSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.operating_mode = None
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
