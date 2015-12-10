import base_schema


class SegmentRangeSchema(base_schema.BaseSchema):
    _schema_name = "segmentRange"
    def __init__(self, py_dict=None):
        """ Constructor to create SegmentRangeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SegmentRangeSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.desc = None
        self.begin = None
        self.end = None
        self.id = None
        self.isUniversal = None

        if py_dict is not None:
             self.get_object_from_py_dict(py_dict)
