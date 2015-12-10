import base_schema

class PagingInfoSchema(base_schema.BaseSchema):
    _schema_name = "pagingInfo"
    def __init__(self, py_dict=None):
        """ Constructor to create LoggingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(PagingInfoSchema, self).__init__()
        self.set_data_type('xml')

        self.pageSize = None
        self.startIndex = None
        self.totalCount = None
        self.sortOrderAscending = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

