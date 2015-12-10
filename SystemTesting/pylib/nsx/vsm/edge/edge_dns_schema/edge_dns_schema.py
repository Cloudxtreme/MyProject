import base_schema
from logging_schema import LoggingSchema
from edge_dns_listeners_schema import DNSListenersSchema
from edge_dns_dnsview_schema import EdgeDNSViewSchema

class DNSSchema(base_schema.BaseSchema):
    _schema_name = "dns"
    def __init__(self, py_dict=None):
        """ Constructor to create DNSSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DNSSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.cacheSize = None
        self.logging = LoggingSchema()
        self.listeners = DNSListenersSchema()
        self.dnsViews = [EdgeDNSViewSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)