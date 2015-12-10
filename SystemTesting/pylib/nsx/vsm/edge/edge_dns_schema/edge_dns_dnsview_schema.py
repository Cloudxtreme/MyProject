import base_schema
from edge_dns_view_match_schema import DNSViewMatchSchema
from edge_dns_forwarders_schema import DNSForwardersSchema


class EdgeDNSViewSchema(base_schema.BaseSchema):
    _schema_name = "dnsView"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgeDNSViewSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeDNSViewSchema, self).__init__()
        self.set_data_type('xml')
        self.viewId = None
        self.name = None
        self.enabled = None
        self.recursion = None
        self.viewMatch = DNSViewMatchSchema()
        self.forwarders = DNSForwardersSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)