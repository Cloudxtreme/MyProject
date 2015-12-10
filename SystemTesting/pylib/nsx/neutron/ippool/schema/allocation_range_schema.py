import base_schema

class AllocationRangeSchema(base_schema.BaseSchema):
    _schema_name = "allocationrange"

    def __init__(self, py_dict=None):
        """ Constructor to create AllocationRangeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(AllocationRangeSchema, self).__init__()
        self.start = None
        self.end = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)