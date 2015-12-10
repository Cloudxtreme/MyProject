import base_schema


class IPRangeDtoSchema(base_schema.BaseSchema):
    _schema_name = 'ipRangeDto'
    def __init__(self, py_dict=None):
        """ Constructor to create IPRangeDtoSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPRangeDtoSchema, self).__init__()
        self.set_data_type('xml')
        self.startAddress = None
        self.endAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
