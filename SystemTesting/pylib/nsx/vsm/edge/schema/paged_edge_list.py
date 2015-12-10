import base_schema
from edge_page import EdgePageSchema
from edge_summary_schema import EdgeSummarySchema

class PagedEdgeListSchema(base_schema.BaseSchema):
    _schema_name = "pagedEdgeList"
    def __init__(self, py_dict=None, list_schema = None):
        """ Constructor to create PagedListSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(PagedEdgeListSchema, self).__init__()
        self.set_data_type('xml')

        self.edgePage    = EdgePageSchema(None, EdgeSummarySchema())

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

