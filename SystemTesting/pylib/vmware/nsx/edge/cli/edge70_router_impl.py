import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.router_interface as router_interface
import vmware.schema.gateway.get_ip_bgp_schema as get_ip_bgp_schema
import vmware.schema.gateway.get_configuration_bgp_schema as get_configuration_bgp_schema  # noqa
import vmware.schema.gateway.get_ip_bgp_neighbors_schema as get_ip_bgp_neighbors_schema  # noqa
import vmware.schema.gateway.get_ip_forwarding_schema as get_ip_forwarding_schema  # noqa
import vmware.schema.gateway.get_ip_route_schema as get_ip_route_schema

pylogger = global_config.pylogger

EXPECT_PROMPT = ['bytes*', 'NSXEdge>']


class Edge70RouterImpl(router_interface.RouterInterface):
    @classmethod
    def get_ip(cls, client_object, table_name=None, get_ip=None):
        """
        Sample Output of command show ip forwarding:

        Codes: C - connected, R - remote,
        > - selected route, * - FIB route
        R>* 0.0.0.0/0 via 10.24.31.253, vNic_3
        C>* 10.24.28.0/22 is directly connected, vNic_3
        C>* 20.20.20.0/24 is directly connected, vNic_2
        C>* 50.50.50.0/24 is directly connected, vNic_0


        #Sample Output of command show ip bgp:
        NSXEdge> show ip bgp

        Status codes: s - suppressed, d - damped, > - best, i - internal
        Origin codes: i - IGP, e - EGP, ? - incomplete

             Network             Next Hop        Metric  LocPrf  Weight  Origin
        >  100.64.1.0/31       169.0.0.1          0     100   32768     ?
        >  192.168.40.0/24     192.168.50.2       0     100      60     i
        >  192.168.50.0/24     192.168.50.2       0     100      60     i
        >  192.168.60.0/24     169.0.0.1          0     100   32768     ?
        >  192.168.70.0/24     169.0.0.1          0     100   32768     ?
        """

        BGP_TABLE = 'bgp'
        FORWARDING_TABLE = 'forwarding'
        PARSER = "raw/horizontalTable"
        VALID_TABLES = [FORWARDING_TABLE, BGP_TABLE]

        get_ip_command = "show ip %s"
        header_keys = None
        skip_head = None

        header_skip_dict = {
            'forwarding': {
                'header_keys': ['Code', 'Network', 'Via', 'NextHop', 'VnicName'],  # noqa
                'skip_head': 2
            },
            'bgp': {
                'header_keys': ['Scode', 'Network', 'NextHop', 'Metric', 'LocPrf', 'Weight', 'Origin'],  # noqa
                'skip_head': 3
            }
        }

        if table_name not in VALID_TABLES:
            raise ValueError("Invalid table name: %r. Valid values are : %r"
                             % (table_name, VALID_TABLES))

        endpoint = get_ip_command % table_name
        header_keys = header_skip_dict[table_name]['header_keys']

        # No. of Header lines to be skipped from output
        skip_head = header_skip_dict[table_name]['skip_head']

        # Execute the command on the Edge VM
        raw_payload = client_object.connection. \
            request(endpoint, EXPECT_PROMPT).response_data

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        if table_name == FORWARDING_TABLE:
            raw_payload = data_parser.marshal_raw_data(
                raw_payload, 'is directly connected,',
                'isdirectlyconnected NULL')

        # Specify the Header keys that we want to insert to the output
        mod_raw_data = data_parser.insert_header_to_raw_data(
            raw_payload, header_keys=header_keys, skip_head=skip_head)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data,
                                             header_keys=header_keys,
                                             skip_head=skip_head,
                                             expect_empty_fields=False)

        # Close the expect connection object
        client_object.connection.close()

        if table_name == FORWARDING_TABLE:
            get_ip_schema_object = get_ip_forwarding_schema. \
                GetIPForwardingSchema(pydict)
        elif table_name == BGP_TABLE:
            get_ip_schema_object = get_ip_bgp_schema.GetIPBGPSchema(pydict)
        return get_ip_schema_object

    @classmethod
    def get_configuration_bgp(cls, client_object,
                              get_configuration_bgp=None):
        """
        Sample Output of command:

        NSXEdge> show configuration bgp
        -----------------------------------------------------------------------
        vShield Edge BGP Routing Protocol Config:
        {
           "bgp" : {
              "gracefulRestart" : false,
              "localAS" : 200,
              "neighbors" : [
                 {
                    "keepAliveTimer" : 60,
                    "ipAddress" : "192.168.50.50",
                    "name" : "Neighbour 1",
                    "description" : "Neighbour 1",
                    "remoteAS" : 200,
                    "password" : "****",
                    "srcIpAddress" : "192.168.50.1",
                    "holdDownTimer" : 180,
                    "weight" : 60
                 }
              ],
              "enabled" : true
           }
        }
        """
        endpoint = "show configuration bgp"
        PARSER = "raw/jsonCli"
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, PARSER, EXPECT_PROMPT, 'bgp')

        get_configuration_bgp_schema_object = get_configuration_bgp_schema. \
            GetConfigurationBGPSchema(mapped_pydict)

        return get_configuration_bgp_schema_object

    @classmethod
    def get_ip_route(cls, client_object, route_filter=None, prefix=None,
                     get_ip_route=None):
        """
        NSXEdge> show ip route

        Codes: O - OSPF derived, i - IS-IS derived, B - BGP derived,
        C - connected, S - static, L1 - IS-IS level-1, L2 - IS-IS level-2,
        IA - OSPF inter area, E1 - OSPF external type 1, E2 - OSPF external type 2,  # noqa
        N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2

        Total number of routes: 4

        C       10.110.60.0/22       [0/0]         via 10.110.63.114
        C       169.0.0.0/28         [0/0]         via 169.0.0.2
        C       169.255.255.240/28   [0/0]         via 169.255.255.241
        C       192.168.3.0/24       [0/0]         via 192.168.3.1
        NSXEdge>
        """

        PARSER = "raw/horizontalTable"
        VALID_ROUTE_FILTERS = ['bgp', 'connected', 'static']

        get_ip_route_command = ["show ip route"]

        if route_filter is None:
            skip_head = 6
        elif route_filter not in VALID_ROUTE_FILTERS:
            raise ValueError("Invalid route filter: %r. Valid values are : %r"
                             % (route_filter, VALID_ROUTE_FILTERS))
        else:
            skip_head = 4
            get_ip_route_command.append(route_filter)
            if prefix:
                get_ip_route_command.append(prefix)

        endpoint = " ".join(get_ip_route_command)
        # Execute the command on the Edge VM
        raw_payload = client_object.connection. \
            request(endpoint, EXPECT_PROMPT).response_data

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        # Specify the Header keys that we want to insert to the output
        header_keys = ['Code', 'Network', 'AdminDist_Metric', 'Via', 'NextHop']

        mod_raw_data = data_parser.insert_header_to_raw_data(
            raw_payload, header_keys=header_keys, skip_head=skip_head)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data,
                                             header_keys=header_keys,
                                             skip_head=skip_head,
                                             expect_empty_fields=False)

        # Close the expect connection object
        client_object.connection.close()

        get_ip_route_schema_object = get_ip_route_schema. \
            GetIPRouteSchema(pydict)
        if route_filter and prefix:
            return get_ip_route_schema_object.table[0]
        return get_ip_route_schema_object

    @classmethod
    def get_ip_bgp_neighbors(cls, client_object, ip_address=None,
                             get_ip_bgp_neighbors=None):
        """
        NSXEdge> show ip bgp neighbors 192.168.50.2

        BGP neighbor is 192.168.50.2,   remote AS 200,
        BGP state = Established, up
        Hold time is 180, Keep alive interval is 60 seconds
        Neighbor capabilities:
                 Route refresh: advertised and received
                 Address family IPv4 Unicast:advertised and received
                 Graceful restart Capability:none
                         Restart remain time: 0
        Received 95 messages, Sent 99 messages
        Default minimum time between advertisement runs is 30 seconds
        For Address family IPv4 Unicast:advertised and received
                 Index 1 Identifier 0x5fc5f6ec
                 Route refresh request:received 0 sent 0
                 Prefixes received 2 sent 2 advertised 2
        Connections established 3, dropped 62
        Local host: 192.168.50.1, Local port: 179
        Remote host: 192.168.50.2, Remote port: 47813

        NSXEdge>
        """
        if ip_address is None:
            raise ValueError("IP address must be a valid value. "
                             "Provided: %r" % ip_address)

        endpoint = "show ip bgp neighbors " + ip_address
        PARSER = "raw/showBgpNeighbors"

        # Execute the command on the Edge VM
        raw_payload = client_object.connection. \
            request(endpoint, EXPECT_PROMPT).response_data

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(raw_payload, delimiter=":")

        # Close the expect connection object
        client_object.connection.close()

        get_ip_bgp_neighbors_schema_object = get_ip_bgp_neighbors_schema. \
            GetIPBGPNeighborsSchema(pydict)
        return get_ip_bgp_neighbors_schema_object

    @classmethod
    def clear_ip_bgp(cls, client_object, clear_ip_bgp=None):
        """
        Clears the BGP configuration
        """
        endpoint = "clear ip bgp neighbor"
        edgepassword = "C@shc0w12345"

        pylogger.info("Executing command on NSX Edge: %s" % endpoint)
        expect_condition, command_output = client_object. \
            connection.execute_command_in_enable_terminal(endpoint,
                                                          ['NSXEdge#'],
                                                          edgepassword)

        # close the expect connection object
        client_object.connection.close()

        pylogger.info("NSX Edge output : %s" % command_output)

        if expect_condition == 0:
            pylogger.info("NSX Edge command %s executed successfully:"
                          % endpoint)
        else:
            pylogger.error("NSX Edge command %s failed to execute" % endpoint)
