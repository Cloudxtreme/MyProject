import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.router_interface as router_interface
import vmware.schema.router.arp_table_schema as arp_table_schema
import vmware.schema.router.logical_router_schema as logical_router_schema
import vmware.schema.router.logical_router_port_schema as lr_port_schema
import vmware.schema.router.route_table_schema as route_table_schema

pylogger = global_config.pylogger


class ESX55RouterImpl(router_interface.RouterInterface):
    VERTICAL_PARSER_TYPE = "raw/flatverticalTable"
    HORIZONTAL_PARSER_TYPE = "raw/horizontalTable"

    @classmethod
    def get_logical_router_ports(cls, client_object, logical_router_id=None,
                                 get_logical_router_ports=None,
                                 get_dhcp_relay_info=None):
        """
        Get the information for all LR Ports (i.e DR LIFs) for the given LR
        instance

        ~ # net-vdr --lif f3ceae2f-dbc8-46ee-9e04-a911a5517917 -l

        DR f3ceae2f-dbc8-46ee-9e04-a911a5517917 LIF Information :

        UUID:                a87496ac-cce9-42c7-ba23-53f45c09e3b6
        Mode:                Routing-Backplane
        Id:                  Overlay:41864
        Ip/Mask:             169.0.0.1/255.255.255.240
        Mac:                 02:50:56:56:44:52
        Connected Dvs:       nsxvswitch
        VXLAN Control Plane: Enabled
        Replication Mode:    0.0.0.2
        State:               Enabled
        Flags:               0x12308
        DHCP Relay:          Not enabled
        """
        pylogger.warn("get_dhcp_relay_inf parameter will be ignored as DHCP "
                      "relay info is provided using the same command as port "
                      "info for ESX")
        command = "net-vdr --lif %s -l" % logical_router_id
        pylogger.info("Getting net-vdr table lif info using: %s" % command)
        logical_router_port_attributes_map = {
            'uuid': 'lrport_uuid',
            'mode': 'mode',
            'id': 'overlay_net_id',
            'ip/mask': 'ip_address',
            'mac': 'macaddress',
            'connected dvs': 'connected_switch',
            'vxlan control plane': 'vxlan_control_plane_status',
            'replication mode': 'replication_mode',
            'state': 'port_state',
            'flags': 'flags',
            'dhcp relay': 'dhcp_relay_servers',
        }
        return client_object.execute_cmd_get_schema(
            command, logical_router_port_attributes_map,
            cls.VERTICAL_PARSER_TYPE,
            lr_port_schema.LogicalRouterPortSchema)

    @classmethod
    def get_logical_routers(cls, client_object, get_logical_routers=None):
        """
        Get the configuration information for all VDR's

        ~ # net-vdr -I -l

        DR Instance Information :
        ---------------------------

        DR UUID:                    f3ceae2f-dbc8-46ee-9e04-a911a5517917
        DR Id:                      0x31dc830a
        Number of Lifs:             2
        Number of Routes:           7
        State:                      Enabled
        Controller IP:              10.146.111.158
        Control Plane IP:           10.146.104.244
        Control Plane Active:       Yes
        Num unique nexthops:        2
        Generation Number:          0
        Edge Active:                No
        """
        command = "net-vdr -I -l"
        pylogger.info("Getting net-vdr list using command %s" % command)
        dr_list_attributes_map = {
            'dr uuid': 'lr_uuid',
            'dr id': 'dr_id',
            'number of lifs': 'number_of_ports',
            'number of routes': 'number_of_routes',
            'state': 'lr_state',
            'controller ip': 'controller_ip',
            'control plane ip': 'control_plane_ip',
            'control plane active': 'control_plane_active',
            'num unique nexthops': 'num_unique_nexthops',
            'generation number': 'generation_number',
            'edge active': 'edge_active',
        }
        return client_object.execute_cmd_get_schema(
            command, dr_list_attributes_map,
            cls.VERTICAL_PARSER_TYPE,
            logical_router_schema.LogicalRouterSchema)

    @classmethod
    def get_route_table(cls, client_object, logical_router_id=None,
                        get_route_table=None):
        """
        Get the routing table for the given LR instance
        ~ # net-vdr --route e1c7d98b-ccd3-41a0-89a2-f413b39e0011 -l

        VDR e1c7d98b-ccd3-41a0-89a2-f413b39e0011 Route Table
        Legend: [U: Up], [G: Gateway], [C: Connected], [I: Interface]
        Legend: [H: Host], [F: Soft Flush] [!: Reject] [E: ECMP]

        Destination      GenMask          Gateway          Flags    Ref Origin   UpTime     Interface  # noqa
        -----------      -------          -------          -----    --- ------   ------     ---------  # noqa
        192.168.1.0      255.255.255.0    0.0.0.0          UCI      1   MANUAL   85334      07ab8440-752c-4faa  # noqa
        192.168.2.0      255.255.255.0    0.0.0.0          UCI      1   MANUAL   85334      3f339d86-5530-41aa  # noqa
        """
        command = "net-vdr --route %s -l" % logical_router_id
        pylogger.info("Getting routing table from net-vdr using: %s" % command)
        route_table_attributes_map = {
            'destination': 'destination',
            'genmask': 'mask',
            'flags': 'dr_flags',
            'gateway': 'next_hop',
            'ref': 'dr_ref',
            'origin': 'origin',
            'uptime': 'route_uptime',
            'interface': 'egress_iface',
        }
        # XXX(dbadiani): This is the number of lines between net-vdr command
        # output start and the header keys for the columns in the output.
        output_lines_to_skip = 4
        # XXX(dbadiani): This is to skip the header key decorator '----' which
        # shows up as the first record in the parsed output dict.
        records_to_skip = 1
        return client_object.execute_cmd_get_schema(
            command, route_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            route_table_schema.RouteTableSchema, skip_records=records_to_skip,
            skip_head=output_lines_to_skip)

    @classmethod
    def read_next_hop(cls, client_object, logical_router_id=None,
                      source_ip=None, destination_ip=None,
                      read_next_hop=None, **kwargs):
        """
        Get the next hop for a given source and destination ip from the DR.
        ~ # net-vdr --route -o resolve -i 10.40.90.1 -e 192.168.1.10 f50f7a65-e809-4241-a62a-ebfa52edf44d  # noqa

        VDR f50f7a65-e809-4241-a62a-ebfa52edf44d Route Table
        Legend: [U: Up], [G: Gateway], [C: Connected], [I: Interface]
        Legend: [H: Host], [F: Soft Flush] [!: Reject] [E: ECMP]

        Destination      GenMask          Gateway          Flags    Ref Origin   UpTime    Interface  # noqa
        -----------      -------          -------          -----    --- ------   ------    ---------  # noqa
        0.0.0.0          0.0.0.0          169.0.0.4        UGE      1   AUTO     14047     810c94ce-3311-4f  # noqa
        """
        command = ("net-vdr --route -o resolve -i %s -e %s %s" %
                   (destination_ip, source_ip, logical_router_id))
        pylogger.info("Getting next hop for source ip: %r and destination ip: "
                      "%r from DR using: %s" % (source_ip, destination_ip,
                                                command))
        next_hop_attributes_map = {
            'destination': 'destination',
            'genmask': 'mask',
            'flags': 'dr_flags',
            'gateway': 'next_hop',
            'ref': 'dr_ref',
            'origin': 'origin',
            'uptime': 'route_uptime',
            'interface': 'egress_iface',
        }
        # XXX(dbadiani): This is the number of lines between net-vdr command
        # output start and the header keys for the columns in the output.
        output_lines_to_skip = 4
        # XXX(dbadiani): This is to skip the header key decorator '----' which
        # shows up as the first record in the parsed output dict.
        records_to_skip = 1
        ret = client_object.execute_cmd_get_schema(
            command, next_hop_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            route_table_schema.RouteTableSchema, skip_records=records_to_skip,
            skip_head=output_lines_to_skip)
        # XXX(dbadiani): Here the return data contains just 1 dictionary so
        # we are not returning table but the dictionary only.
        return ret.table[0]

    @classmethod
    def get_dr_arp_table(cls, client_object, logical_router_id=None,
                         lr_port_id=None, get_dr_arp_table=None):
        """
        Get the routing table for the given LR instance

        ARP table for the DR:
        ~ # net-vdr --nbr -l <logical_router_id>

        VDR e1c7d98b-ccd3-41a0-89a2-f413b39e0011 ARP Information :
        Legend: [S: Static], [V: Valid], [P: Proxy], [I: Interface]
        Legend: [N: Nascent], [L: Local], [D: Deleted], [K: linKlif]

        Network           Mac                  Flags      Expiry     SrcPort    Refcnt   Interface  # noqa
        -------           ---                  -----      ------     -------    ------   ---------
        192.168.1.1       02:50:56:56:44:52    VI         permanent  0          1        07ab8440-752c-4fd0-9f36-2fbecb9b5016  # noqa
        192.168.2.1       02:50:56:56:44:52    VI         permanent  0          1        3f339d86-5530-418e-9eda-111d2f626327a  # noqa

        ARP table for a DR interface:
        ~ # net-vdr --nbr -n <logical_router_port_id> -l <logical_router_id>  # noqa

        VDR e1c7d98b-ccd3-41a0-89a2-f413b39e0011 ARP Information :
        Legend: [S: Static], [V: Valid], [P: Proxy], [I: Interface]
        Legend: [N: Nascent], [L: Local], [D: Deleted], [K: linKlif]

        Network           Mac                  Flags      Expiry     SrcPort    Refcnt   Interface  # noqa
        -------           ---                  -----      ------     -------    ------   ---------
        192.168.1.1       02:50:56:56:44:52    VI         permanent  0          1        07ab8440-752c-4fd0-9f36-2fbecb9b5016  # noqa
        """
        port_arp_cmd = ""
        if lr_port_id is not None:
            port_arp_cmd = "-n %s " % lr_port_id
        command = "net-vdr --nbr %s-l %s" % (port_arp_cmd, logical_router_id)
        pylogger.info("Getting routing table from net-vdr using: %s" % command)
        route_table_attributes_map = {
            'network': 'ip',
            'mac': 'mac',
            'flags': 'dr_flags',
            'expiry': 'expiry',
            'srcport': 'srcport',
            'refcnt': 'refcnt',
            'interface': 'logical_router_port_id'
        }
        # XXX(dbadiani): This is the number of lines between net-vdr command
        # output start and the header keys for the columns in the output.
        output_lines_to_skip = 4
        # XXX(dbadiani): This is to skip the header key decorator '----' which
        # shows up as the first record in the parsed output dict.
        records_to_skip = 1
        return client_object.execute_cmd_get_schema(
            command, route_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            arp_table_schema.ArpTableSchema, skip_records=records_to_skip,
            skip_head=output_lines_to_skip)

    @classmethod
    def get_logical_router_port_info(cls, client_object,
                                     logical_router_id=None,
                                     port_id=None,
                                     get_logical_router_port_info=None):
        """
        Get the information for a given LR Port (i.e DR LIF) for the given LR
        instance

        ~ # net-vdr --lif -l -n 4db4ee8c-dd38-4d5e-9268-c3efee17b650 2fa62c6e-1dc2-43fa-9e60-83c969bb6e7d  # noqa

        VDR 2fa62c6e-1dc2-43fa-9e60-83c969bb6e7d LIF Information :

        Name:                4db4ee8c-dd38-4d5e-9268-c3efee17b650
        Mode:                Routing, Distributed, Internal
        Id:                  Overlay:31752
        Ip/Mask:             192.168.9.1/255.255.255.0
        Mac:                 02:50:56:56:44:52
        Connected Dvs:       nsxvswitch
        VXLAN Control Plane: Enabled
        VXLAN Multicast IP:  0.0.0.1
        State:               Enabled
        Flags:               0x2288
        DHCP Relay:          Not enabled
        """
        command = "net-vdr --lif -l -n %s %s" % (port_id, logical_router_id)
        pylogger.info("Getting net-vdr table lif info using: %s" % command)
        logical_router_port_attributes_map = {
            'name': 'port_id',
            'dhcp relay': 'dhcp_relay_servers',
            'connected dvs': 'connected_switch',
            'id': 'overlay_net_id',
            'ip': 'ip_address',
            'mac': 'macaddress',
            'vxlan control plane': 'vxlan_control_plane_status',
            'vxlan multicast ip': 'multicast_ip',
            'state': 'port_state'
        }
        return client_object.execute_cmd_get_schema(
            command, logical_router_port_attributes_map,
            cls.VERTICAL_PARSER_TYPE,
            lr_port_schema.LogicalRouterPortSchema)

    @classmethod
    def disconnect_vdr_port_from_switch(cls, client_object, switch_name):
        """
        Disconnect VDR port from logical switch.
        """
        switch_name = utilities.get_default(switch_name, 'nsxvswitch')
        command = "net-vdr --connection -d -s %s" % switch_name
        try:
            client_object.connection.request(command)
        except Exception, error:
            pylogger.error("Exception thrown when disconnecting vdr port: %r" %
                           error)
            raise
