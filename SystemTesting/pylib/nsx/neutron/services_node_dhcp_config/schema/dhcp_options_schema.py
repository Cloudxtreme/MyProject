import base_schema
import resource_link_schema

class DhcpOptionsSchema(base_schema.BaseSchema):
    _schema_name = "dhcpoptions"

    def __init__(self, py_dict=None):
        """ Constructor to create DhcpOptionsSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(DhcpOptionsSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.dns_config_id = None
        self.routers = [str]
        self.hostname = None
        self.domain_name_servers = [str]
        self.domain_name = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.default_lease_time = None
        self.schema = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)