import re

import vmware.common.global_config as global_config
import vmware.common.regex_utils as regex_utils
import vmware.interfaces.nsx_interface as nsx_interface
import vmware.linux.ovs.ovs_helper as ovs_helper
import vmware.parsers.flat_vertical_table_parser as flat_vertical_table_parser
import vmware.parsers.horizontal_table_parser as horizontal_table_parser
import vmware.schema.ipfix_table_schema as ipfix_table_schema
import vmware.schema.router.arp_table_schema as arp_table_schema
import vmware.schema.router.logical_router_port_schema as logical_router_port_schema  # noqa
import vmware.schema.router.logical_router_schema as logical_router_schema
import vmware.schema.router.route_table_schema as route_table_schema
import vmware.schema.switch.tunnel_table_schema as tunnel_table_schema

pylogger = global_config.pylogger
OVS = ovs_helper.OVS


class DefaultNSXImpl(nsx_interface.NSXInterface):

    APPCTL = "ovs-appctl"
    NSXA_SOCKET = "/var/run/openvswitch/nsxa-ctl"
    L3D = "ovs-l3d"
    VSCTL = "ovs-vsctl"
    IPFIX_TABLE_TYPE = 'raw/flatverticalTable'
    HORIZONTAL_PARSER_TYPE = "raw/horizontalTable"

    @classmethod
    def get_logical_routers(cls, client_object, get_logical_routers=None):
        command = "{} -t {} vdr/list".format(cls.APPCTL, cls.NSXA_SOCKET)
        pylogger.info("Getting vdr list using command {}".format(command))
        vdr_list_attributes_map = {
            'vdr name': 'lr_uuid',
            'vdr id': 'vdr_id',
        }
        return client_object.execute_cmd_get_schema(
            command, vdr_list_attributes_map,
            horizontal_table_parser.PARSER_TYPE,
            logical_router_schema.LogicalRouterSchema,
            header_keys=('VDR Name', 'VDR ID'))

    @classmethod
    def get_logical_router_ports(cls, client_object, logical_router_id=None,
                                 get_logical_router_ports=None,
                                 get_dhcp_relay_info=None):
        """
        Get the information for all LR Ports (i.e DR LIFs) for the given LR
        instance
        # ovs-appctl -t /var/run/openvswitch/nsxa-ctl vdr/lif 3dd7b1b2-58fd-45b5-949b-c1ae93b02b12  # noqa
        VDR: 3dd7b1b2-58fd-45b5-949b-c1ae93b02b12
                                    LIF Name                   IP/Mask         Mac Address VNI     Flags  # noqa
        33abdc2f-23aa-4fbb-b206-74f3feff09ce 192.168.1.1/255.255.255.0   02:50:56:56:44:52 9096        0  # noqa
        b56a7088-a8ef-476b-958d-add1bc31435f 169.0.0.1/255.255.255.240   02:50:56:56:44:52 54152       2  # noqa
        352d111b-b090-469f-8136-72e716e3e5d9 192.168.2.1/255.255.255.0   02:50:56:56:44:52 50056       0  # noqa
        """
        if bool(get_dhcp_relay_info):
            return cls.get_lr_ports_with_dhcp(client_object)
        command = ("{} -t {} vdr/lif {}".format(cls.APPCTL, cls.NSXA_SOCKET,
                                                logical_router_id))
        pylogger.info("Getting vdr lif list using command {}".format(command))
        lrport_attrmap = {
            'lif name': 'lrport_uuid',
            'ip/mask': 'ip_address',
            'mac address': 'macaddress',
            'vni': 'overlay_net_id',
            'flags': 'flags',
        }
        return client_object.execute_cmd_get_schema(
            command, lrport_attrmap, horizontal_table_parser.PARSER_TYPE,
            logical_router_port_schema.LogicalRouterPortSchema,
            header_keys=("LIF Name", "IP/Mask", "Mac Address", "VNI", "Flags"),
            skip_head=1)

    @classmethod
    def get_route_table(cls, client_object, logical_router_id=None,
                        get_route_table=None):
        """
        Get the routing table for the given LR instance
        # ovs-appctl -t /var/run/openvswitch/nsxa-ctl vdr/route 24b2b95e-8d3e-464c-99cf-c150c28817ca # noqa
        VDR: 24b2b95e-8d3e-464c-99cf-c150c28817ca
         Destination             GenMask             Gateway    Interface
            20.0.0.0       255.255.255.0             0.0.0.0    7b768b65-4866-436d-8c69-8d30bec54dbf # noqa
            10.0.0.0       255.255.255.0             0.0.0.0    fef0034a-f51d-44f0-8c65-83b42deef92a # noqa
           30.30.1.0       255.255.255.0             0.0.0.0    db0ffc48-03ed-475f-9643-ec593a73f3c6 # noqa
         192.200.0.0         255.255.0.0            20.0.0.1    7b768b65-4866-436d-8c69-8d30bec54dbf # noqa
         192.100.0.0         255.255.0.0            10.0.0.1    fef0034a-f51d-44f0-8c65-83b42deef92a # noqa
             0.0.0.0             0.0.0.0           30.30.1.2    db0ffc48-03ed-475f-9643-ec593a73f3c6 # noqa
             0.0.0.0             0.0.0.0           30.30.1.3    db0ffc48-03ed-475f-9643-ec593a73f3c6 # noqa
        """
        command = ("{} -t {} vdr/route {}".format(cls.APPCTL, cls.NSXA_SOCKET,
                                                  logical_router_id))
        pylogger.info("Getting routing table from net-vdr using: %s" % command)
        route_table_attributes_map = {
            'genmask': 'mask',
            'gateway': 'next_hop',
            'interface': 'egress_iface',
        }
        # XXX(dbadiani): This is the number of lines between vdr/route  command
        # output start and the header keys for the columns in the output.
        output_lines_to_skip = 1
        return client_object.execute_cmd_get_schema(
            command, route_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            route_table_schema.RouteTableSchema,
            skip_head=output_lines_to_skip)

    @classmethod
    def get_dr_arp_table(cls, client_object, logical_router_id=None,
                         lr_port_id=None, get_dr_arp_table=None):
        """
        Get the ARP table entries.
        # ovs-appctl -t ovs-l3d neigh/show
                       UUID                   Cache IPAddress           HWAddress     State    Timeout               Flow Table # noqa
        8c132def-b11f-411b-bb58-1cba54d3f36d egress 192.168.1.11    00:23:20:ca:a1:2a reach        53s 0x800000000000003d    21 # noqa
        8c132def-b11f-411b-bb58-1cba54d3f36d egress 192.168.1.10    00:23:20:fa:03:0b reach        89s 0x800000000000005b    21 # noqa
        """
        command = "%s -t ovs-l3d neigh/show" % cls.APPCTL
        pylogger.info("Getting ARP entries using %s" % command)
        arp_table_attributes_map = {
            'ipaddress': 'ip',
            'hwaddress': 'mac',
        }
        header_keys = ('UUID', 'Cache', 'IPAddress', 'HWAddress', 'State',
                       'Timeout', 'Flow', 'Table')
        return client_object.execute_cmd_get_schema(
            command, arp_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            arp_table_schema.ArpTableSchema, header_keys=header_keys)

    @classmethod
    def get_tunnel_ports_remote_ip(cls, client_object, **kwargs):
        """
        Get the remote IPs associated with all tunnel ports and
        its forwarding state.

        @type client_object: BaseClient.
        @param client_object: Used to pass commands to the host.
        @rtype: dict.
        @return: Dictionary of the form.
            {'table': [{'remote_ip': <ip1>}, {'forwarding_state': <string>},
                       ...]}
        """
        table = []
        cmd = OVS.list_columns_in_table('interface', ['options', 'bfd_status'],
                                        format_type='table')
        out = client_object.connection.request(cmd).response_data
        pattern = 'remote_ip="%s".*forwarding="%s".*' % (regex_utils.ip,
                                                         "(true|false)")
        match_data = re.findall(pattern, out)
        for data in match_data:
            py_dict = {}
            py_dict['remote_ip'] = data[0]
            py_dict['forwarding_state'] = data[1]
            table.append(py_dict)
        return tunnel_table_schema.TunnelTableSchema(
            py_dict={'table': table})

    @classmethod
    def get_lr_ports_with_dhcp(cls, client_object):
        """
        Get the vdr lif port config along with the DHCP relay configuration.

        # ovs-appctl -t ovs-l3d router-port/show

        Router Port: ace9d5aa-7ac0-4eb3-b280-ad0e87b3127a
        IP address: 192.168.9.1/24
        MAC address: 02:50:56:56:44:52
        DHCP relay to: 0.0.0.0

        Router Port: 461c7b02-5abf-4377-bd1a-c8884f05e044
        IP address: 192.168.8.1/24
        MAC address: 02:50:56:56:44:52
        DHCP relay to: 0.0.0.0 192.168.9.4
        """
        command = ("{} -t {} router-port/show".format(cls.APPCTL, cls.L3D))
        pylogger.info("Getting vdr lif config along with DHCP Relay config "
                      "using command {}".format(command))
        dhcp_relay_attributes_map = {
            'ip address': 'ip_address',
            'mac address': 'macaddress',
            'router port': 'lrport_uuid',
            'dhcp relay to': 'dhcp_relay_servers'
        }
        lr_port_schema_obj = client_object.execute_cmd_get_schema(
            command, dhcp_relay_attributes_map,
            flat_vertical_table_parser.PARSER_TYPE,
            logical_router_port_schema.LogicalRouterPortSchema)
        # The below code would sort the dhcp_relay_servers attribute value
        # as "192.168.9.6 192.168.9.4" to "192.168.9.4 192.168.9.6."
        for index, value in enumerate(lr_port_schema_obj.table):
            if value.dhcp_relay_servers:
                lr_port_schema_obj.table[index].dhcp_relay_servers = sorted(
                    value.dhcp_relay_servers.split())
        return lr_port_schema_obj

    @classmethod
    def read_next_hop(cls, client_object, logical_router_id=None,
                      destination_ip=None, source_ip=None, ip_proto=None,
                      destination_mac=None, source_mac=None, eth_type=None,
                      vlan_id=None, dst_port=None, src_port=None,
                      read_next_hop=None):
        """
        Get the next hop based on the packet fields from the DR.
        ~ # ovs-appctl -t /var/run/openvswitch/nsxa-ctl vdr/nexthop 286fd355-65a0-45a9-b8d3-832fc5673db9 100.100.10.2 192.100.1.2 6 00:23:22:11:22:33 00:23:22:11:22:33 0x800 0 0 0  # noqa

        Next Hop                                        Interface
        30.30.1.3              be92f095-55ea-4f2b-94b7-15daadfe84c

        If there is a unique next hop for the destination, providing just the destination IP is sufficient.  # noqa

        root@b2b4ed2ae218:~# ovs-appctl -t /var/run/openvswitch/nsxa-ctl vdr/nexthop 286fd355-65a0-45a9-b8d3-832fc5673db9 192.100.10.1  # noqa
        Next Hop                                        Interface
        10.0.0.1              740ccb4b-6075-4cfa-b449-6efefae5d278

        If there are multiple possible next hop candidates for the destination IP, the CLI will fail and ask you to enter all the 10 parameters. This is the ECMP case:  # noqa

        root@b2b4ed2ae218:~# ovs-appctl -t /var/run/openvswitch/nsxa-ctl vdr/nexthop 286fd355-65a0-45a9-b8d3-832fc5673db9 100.100.10.2  # noqa
        ECMP destination: All arguments need to be provided for hash calculation.  # noqa
        vdr/nexthop [VDR NAME] [DST IP] [SRC IP] [IP PROTO] [DST ETH] [SRC ETH] [ETH TYPE] [VLAN] [DST PORT] [SRC PORT]  # noqa
        ovs-appctl: /var/run/openvswitch/nsxa-ctl: server returned an error
        """
        # XXX(mbindal) Move the method to a new module default_router_impl.py
        command_params = [destination_ip, source_ip, ip_proto, destination_mac,
                          source_mac, eth_type, vlan_id, dst_port, src_port]
        # Replacing parameter values with their defaults if None provided.
        for index, params in enumerate(command_params):
            if params is None:
                command_params[index] = '0'
        command_params = " ".join(command_params)
        command = ("{} -t {} vdr/nexthop {} {}".format(
            cls.APPCTL, cls.NSXA_SOCKET, logical_router_id, command_params))
        pylogger.info("Getting next hop for source ip: %r and destination ip: "
                      "%r from DR using: %s" % (source_ip, destination_ip,
                                                command))
        next_hop_attributes_map = {
            'next hop': 'next_hop',
            'interface': 'egress_iface',
        }
        header_keys = ('Next Hop', 'Interface')
        ret = client_object.execute_cmd_get_schema(
            command, next_hop_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            route_table_schema.RouteTableSchema, header_keys=header_keys)
        # XXX(mbindal): Here the return data contains just 1 dictionary so
        # we are not returning table but the dictionary only.
        return ret.table[0]

    @classmethod
    def get_ipfix_config(cls, client_object, **kwargs):
        """
        Returns the IPFIX configuration on a KVM host obtained using the
        ovs-vsctl list ipfix command.

        Sample output:
        # ovs-vsctl list ipfix
        _uuid               : 554a9d20-80d2-48ea-9721-23c44fdd2a13
        cache_active_timeout: 2
        cache_max_flows     : []
        external_ids        : {}
        obs_domain_id       : 123
        obs_point_id        : 456
        sampling            : 10
        targets             : ["10.33.74.48:9999"]

        @type client_object: BaseClient.
        @param client_object: Used to pass commands to the host.
        @rtype: ipfix_table_schema.IPFIXTableSchema.
        @return: Returns the IPFIXTableSchema object.
        """
        command = '%s list ipfix' % cls.VSCTL
        pylogger.info("Getting IPFIX configuration using: %s" % command)
        ipfix_table_attributes_map = {
            'idle timeout': 'idle_timeout',
            'cache_active_timeout': 'flow_timeout',
            'sampling': 'packet_sample_probability',
            'cache_max_flows': 'max_flows',
            'obs_domain_id': 'domain_id',
            'targets': 'collector'}
        # IPFIX has 1 global configuration. Hence no need to return the entire
        # list. Instead just return the 1st and only element.
        result = client_object.execute_cmd_get_schema(
            command, ipfix_table_attributes_map, cls.IPFIX_TABLE_TYPE,
            ipfix_table_schema.IPFIXTableSchema).table[0]
        return cls._format_ipfix_config(result)

    @classmethod
    def _format_ipfix_config(cls, schema_obj):
        """
        Converts the given schema object to a format consumable by the test.
        1) Stripts the square brackets and double quotes around ["ip:port"].
        2) Splits collector ip:port to separate keys as they were used while
           configuration.

        @type schema_obj: ipfix_table_schema.IPFIXTableSchema.
        @param schema_obj: IPFIXTableSchema object.
        @rtype: ipfix_table_schema.IPFIXTableSchema.
        @return: Returns the formatted IPFIXTableSchema object.
        """
        pattern = '\["(.*):(\d+)"\]'
        match = re.search(pattern, schema_obj.collector)
        if match:
            schema_obj.ip_address, schema_obj.port = match.groups()
            # Delete the unwanted key.
            del schema_obj.collector
        else:
            pylogger.warn(("Could not find match object for pattern <ip:port> "
                           "in %s") % schema_obj.collector)
        return schema_obj
