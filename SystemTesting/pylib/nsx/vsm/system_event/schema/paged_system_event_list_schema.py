import base_schema
from sys_event_data_page_schema import DataPageSchema

class PagedSystemEventListSchema(base_schema.BaseSchema):
    _schema_name = "pagedSystemEventList"

    def __init__(self, py_dict=None):
        """ Constructor to create PagedSystemEventListSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(PagedSystemEventListSchema, self).__init__()
        self.set_data_type("xml")
        self.dataPage = DataPageSchema()


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
