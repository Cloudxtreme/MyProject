import base_schema
from sys_event_paging_info_schema import PagingInfoSchema
from system_event_schema import SystemEventSchema

class DataPageSchema(base_schema.BaseSchema):
    _schema_name = "dataPage"

    def __init__(self, py_dict=None):
        """ Constructor to create DataPageSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DataPageSchema, self).__init__()
        self.set_data_type("xml")
        self.pagingInfo = PagingInfoSchema()
        self.systemEvent = [SystemEventSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
