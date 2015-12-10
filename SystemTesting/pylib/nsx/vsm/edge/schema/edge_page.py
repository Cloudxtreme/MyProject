import base_schema
from edge_summary_schema import EdgeSummarySchema
from paging_info_schema import PagingInfoSchema

class EdgePageSchema(base_schema.BaseSchema):
    _schema_name = "edgePage"
    def __init__(self, py_dict=None, list_schema = None):
        """ Constructor to create EdgePageSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgePageSchema, self).__init__()
        self.set_data_type('xml')

        self.pagingInfo = PagingInfoSchema()
        self.list_schema = [list_schema]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

