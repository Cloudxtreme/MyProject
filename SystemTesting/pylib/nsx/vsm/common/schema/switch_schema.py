import base_schema
from scope_schema import ScopeSchema
from type_schema import TypeSchema


class SwitchSchema(base_schema.BaseSchema):
    _schema_name = "switch"
    """"""

    def __init__(self, py_dict=None):
        """ Constructor to create SwitchSchema object

        @param schema_object instance of BaseSchema class
        @return status http response state
        """
        super(SwitchSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.revision = None
        self.type = TypeSchema()
        self.name = None
        self.extendedAttributes = None
        self.clientHandle = None
        self.scope = ScopeSchema()

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
