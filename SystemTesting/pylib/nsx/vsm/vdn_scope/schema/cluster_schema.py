import base_schema
from scope_schema import ScopeSchema
from type_schema import TypeSchema


class ClusterSchema(base_schema.BaseSchema):
    _schema_name = "cluster"
    def __init__(self, py_dict=None):
        """ Constructor to create ClusterSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ClusterSchema, self).__init__()
        self.objectId = None
        self.type = TypeSchema()
        self.name = None
        self.scope = ScopeSchema()

        if py_dict is not None:
            if 'objectId' in py_dict:
                self.objectId = py_dict['objectId']

