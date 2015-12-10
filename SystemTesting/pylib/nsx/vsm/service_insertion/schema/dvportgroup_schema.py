import base_schema
from type_object_schema import TypeObjectSchema
from datacenter_scope_schema import DatacenterScopeSchema

class DVPortGroupSchema(base_schema.BaseSchema):
    _schema_name = "dvPortGroup"

    def __init__(self, py_dict=None):
        """ Constructor to create DVPortGroupSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DVPortGroupSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.revision = None
        self.type = TypeObjectSchema()
        self.name = None
        self.scope = DatacenterScopeSchema()
        self.clientHandle = None
        self.extendedAttributes = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
