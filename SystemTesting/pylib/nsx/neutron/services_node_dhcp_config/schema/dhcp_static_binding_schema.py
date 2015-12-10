import base_schema
import resource_link_schema
import dhcp_options_schema

class DhcpStaticBindingSchema(base_schema.BaseSchema):
    _schema_name = "dhcpstaticbinding"

    def __init__(self, py_dict=None):
        """ Constructor to create DhcpStaticBindingSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(DhcpStaticBindingSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.vif_id = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.mac_address = None
        self.schema = None
        self.ip_address = None
        self.dhcp_options = dhcp_options_schema.DhcpOptionsSchema()
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)