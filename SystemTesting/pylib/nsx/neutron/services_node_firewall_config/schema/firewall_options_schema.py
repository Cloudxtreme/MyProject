import base_schema
import resource_link_schema

class FirewallOptionsSchema(base_schema.BaseSchema):
    _schema_name = "firewalloptions"

    def __init__(self, py_dict=None):

        super(FirewallOptionsSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.icmp6_timeout = None
        self.log_invalid_traffic = None
        self.tcp_send_resets_for_closed_servicenode_ports = None
        self.tcp_pick_ongoing_conn = None
        self.tcp_timeout_established = None
        self.icmp_timeout = None
        self.udp_timeout = None
        self.tcp_timeout_close = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.tcp_allow_outofwindow_packets = None
        self.ip_generic_timeout = None
        self.tcp_timeout_open = None
        self.schema = None
        self.drop_invalid_traffic = None
        self.revision = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)