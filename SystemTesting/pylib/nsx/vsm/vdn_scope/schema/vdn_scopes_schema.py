import base_schema
from vdn_scope_schema import VDNScopeSchema

class VDNScopesSchema(base_schema.BaseSchema):
    _schema_name = 'vdnScopes'
    def __init__(self, py_dict=None):
        """ Constructor to create VDNScopesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VDNScopesSchema, self).__init__()
        self.set_data_type('xml')
        self.vdnScope = [VDNScopeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
