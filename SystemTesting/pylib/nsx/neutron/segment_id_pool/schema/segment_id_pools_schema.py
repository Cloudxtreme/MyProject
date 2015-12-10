import base_schema
from resource_link_schema import ResourceLinkSchema

class SegmentIDPoolsSchema(base_schema.BaseSchema):
    _schema_name = "segmentidpools"
    def __init__(self, py_dict=None):
        """ Constructor to create SegmentIDPoolsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SegmentIDPoolsSchema, self).__init__()
        self.set_data_type('json')
        self.start = None
        self.end = None
        self.id = None

        self._self = ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self._create_time = None
        self._links = [ResourceLinkSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None



        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
