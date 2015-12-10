import base_schema
from edge_firewall_schema import FirewallSchema
from edge_routing_schema import EdgeRoutingSchema
from edge_dhcp_schema import DHCPSchema
from edge_nat_schema import EdgeNATSchema
from edge_l2vpn_schema import L2VPNSchema
from edge_syslog_schema import SysLogSchema
from bridges_schema import BridgesSchema
from edge_high_availability_schema import HighAvailabilitySchema
from edge_dns_schema import DNSSchema
from edge_ipsec_schema import IPSecSchema
from edge_load_balancer_schema import LoadBalancerSchema
from edge_sslvpnconfig_schema import SSLVPNConfigSchema


class FeaturesSchema(base_schema.BaseSchema):
    _schema_name = "features"
    def __init__(self, py_dict=None):
        """ Constructor to create GatewayServicesEdgeFeaturesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FeaturesSchema, self).__init__()
        self.set_data_type('xml')
        self.l2Vpn = L2VPNSchema()
        self.firewall = FirewallSchema()
        self.sslvpnConfig = SSLVPNConfigSchema()
        self.dns = DNSSchema()
        self.routing = EdgeRoutingSchema()
        self.highAvailability = HighAvailabilitySchema()
        self.syslog = SysLogSchema()
        self.loadBalancer = LoadBalancerSchema()
        self.ipsec = IPSecSchema()
        self.dhcp = DHCPSchema()
        self.nat = EdgeNATSchema()
        self.bridges = BridgesSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)