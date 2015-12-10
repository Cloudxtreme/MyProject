import base_schema
from paging_info_schema import PagingInfoSchema

class DataPageSchema(base_schema.BaseSchema):
    _schema_name = "dataPage"
    def __init__(self, py_dict=None, list_schema = None):
        """ Constructor to create LoggingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DataPageSchema, self).__init__()
        self.set_data_type('xml')

        self.pagingInfo = PagingInfoSchema()
        self.list_schema = [list_schema]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

