import base_schema
import resource_link_schema

class DhcpIPRangeSchema(base_schema.BaseSchema):
    _schema_name = "dhcpiprange"

    def __init__(self, py_dict=None):
        """ Constructor to create DhcpIPRangeSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(DhcpIPRangeSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.display_name = None
        self.range = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.revision = None
        self.schema = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)