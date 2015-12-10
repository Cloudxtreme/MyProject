import base_schema
import resource_link_schema
import dhcp_ip_range_schema
import dhcp_static_binding_schema
import dhcp_options_schema

class InterfaceDhcpConfigSchema(base_schema.BaseSchema):
    _schema_name = "interfacedhcpconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create InterfaceDhcpConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(InterfaceDhcpConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.enabled = None
        self.ip_ranges = [dhcp_ip_range_schema.DhcpIPRangeSchema()]
        self.interface_id = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.static_bindings = [dhcp_static_binding_schema.DhcpStaticBindingSchema()]
        self.schema = None
        self.dhcp_options = dhcp_options_schema.DhcpOptionsSchema()
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)