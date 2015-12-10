import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema

class NSXManagerInfoSchema(base_schema.BaseSchema):
    _schema_name = "nsxManagerInfo"

    def __init__(self, py_dict=None):
        """ Constructor to create IPSet object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXManagerInfoSchema, self).__init__()
        self.set_data_type('xml')
        self.nsxManagerIp = None
        self.nsxManagerUsername = None
        self.nsxManagerPassword = None
        self.certificateThumbprint = None
        self.isPrimary = None
        self.revision = None
        self.uuid = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
