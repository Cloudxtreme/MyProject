import base_schema


class OspfCliRedistributeRuleSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "ospfredistributeruleschema"
    def __init__(self, py_dict=None):
        """ Constructor to create OspfRedistributeRuleSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(OspfCliRedistributeRuleSchema, self).__init__()


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


