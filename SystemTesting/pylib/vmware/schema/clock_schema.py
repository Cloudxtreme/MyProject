import vmware.common.base_schema as base_schema


class ClockSchema(base_schema.BaseSchema):
    _schema_name = "ClockSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ClockSchema object
        """
        super(ClockSchema, self).__init__()
        self.hr_min_sec = None
        self.day = None
        self.date = None
        self.month = None
        self.year = None
        self.timezone = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)