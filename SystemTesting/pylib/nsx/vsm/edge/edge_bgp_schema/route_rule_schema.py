import base_schema
from from_schema import FromSchema


class RuleSchema(base_schema.BaseSchema):
    _schema_name = "rule"

    def __init__(self, py_dict=None):
        """ Constructor to create RuleSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RuleSchema, self).__init__()
        self.set_data_type("xml")
        self.action = None
        self.fromprotocol = FromSchema()
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
