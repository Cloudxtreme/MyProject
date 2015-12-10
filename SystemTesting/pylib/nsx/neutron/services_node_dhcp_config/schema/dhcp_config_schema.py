import base_schema
import resource_link_schema
import tag_schema
import interface_dhcp_config_schema
import dhcp_options_schema

class DhcpConfigSchema(base_schema.BaseSchema):
    _schema_name = "dhcpconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create DhcpConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(DhcpConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [tag_schema.TagSchema()]
        self.enabled = None
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.config_elements = [interface_dhcp_config_schema.InterfaceDhcpConfigSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.dhcp_options = dhcp_options_schema.DhcpOptionsSchema()
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)