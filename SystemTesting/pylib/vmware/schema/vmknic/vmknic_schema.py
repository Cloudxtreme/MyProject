import vmware.common.base_schema as base_schema

class VmknicSchema(base_schema.BaseSchema):

    def __init__(self,
                 connection_cookie=None,
                 portgroup_key=None,
                 port_key=None,
                 switch_uuid=None,
                 external_id=None,
                 ip=None,
                 mac=None,
                 mtu=None,
                 netstack_instance_key=None,
                 opaque_network_id=None,
                 opaque_network_type=None,
                 pinned_pnic=None,
                 portgroup=None,
                 tso=None,
                 dhcp=None,
                 subnet_mask=None):


        self.connection_cookie = connection_cookie
        self.portgroup_key = portgroup_key
        self.port_key = port_key
        self.switch_uuid = switch_uuid
        self.external_id = external_id
        self.ip = ip
        self.mac = mac
        self.mtu = mtu
        self.netstack_instance_key = netstack_instance_key
        self.opaque_network_id = opaque_network_id
        self.opaque_network_type = opaque_network_type
        self.pinned_pnic = pinned_pnic
        self.portgroup = portgroup
        self.tso = tso
        self.dhcp = dhcp
        self.subnet_mask = subnet_mask

    def get_dict(self):
        return self.__dict__
