import base_schema
from edge_schema import EdgeSchema
from paged_edge_list import PagedEdgeListSchema

class EdgesSchema(base_schema.BaseSchema):
    _schema_name = "edges"
    def __init__(self, py_dict = None):
        """ Constructor to create EdgesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgesSchema, self).__init__()
        self.set_data_type('xml')
        self.pagedEdgeList = PagedEdgeListSchema()

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

