import vmware.common.logger as logger
import re
import result
import connection
import base_client
import vsm_client
import edge_schema
from vsm import VSM
from edge_schema import EdgeSchema
from nsx_edge_schema import NSXEdgeSchema
from paged_edge_list import PagedEdgeListSchema
from address_group_schema import AddressGroupSchema
from appliances_schema import ApplianceSchema
from edge_schema import EdgeSchema
from interfaces_schema import InterfacesSchema
from interface_schema import InterfaceSchema
from expect_client import ExpectClient
import vmware.common.global_config as global_config
import tasks
import vmware.common as common
from edge_centralized_api_cli_schema import EdgeCentralizedApiCliSchema
pylogger = global_config.pylogger
import vmware.common.utilities as utilities


class Edge(vsm_client.VSMClient):
    def __init__(self, vsm, version='4.0'):
        """ Constructor to create edge managed object

        @param vsm object on which edge has to be configured
        """
        super(Edge, self).__init__()
        self.log = global_config.pylogger
        self.set_connection(vsm.get_connection())
        # TODO: Is this the right way to change apiHeader if URL
        # base is changing.
        # In case of edge it is api/4.0 and not api/2.0
        self.connection.api_header = '/api/%s' % version
        self.set_create_endpoint("/edges")
        if version == '4.0':
            self.schema_class = 'edge_schema.EdgeSchema'
        else:
            self.schema_class = 'nsx_edge_schema.NSXEdgeSchema'
        self.id = None
        self.location_header = None

    def upgrade(self):
        """ Method to upgrade VSE
        """
        temp_ep = self.create_endpoint
        temp_id = self.id
        temp_header = self.connection.api_header
        self.connection.api_header = '/api/3.0'
        self.create_endpoint = "/edges/" + str(temp_id) + "?action=upgrade"
        schema_object = EdgeSchema()
        result_obj = super(Edge, self).create(schema_object)
        self.id = temp_id
        self.create_endpoint = temp_ep
        self.connection.api_header = temp_header
        return result_obj

    @tasks.thread_decorate
    def create(self, schema_object):
        self.response = self.request('POST', self.create_endpoint,
                                     schema_object.get_data_without_empty_tags(self.content_type))

        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        response = result_obj.get_response()
        location = response.getheader("Location")
        self.log.debug("Location header is %s" % location)
        self.location_header = location

        if location is not None:
            self.id = location.split('/')[-1]
            result_obj.set_response_data(self.id)
        return result_obj

    def query(self):
        edges = PagedEdgeListSchema()
        edges.set_data(self.base_query(), self.accept_type)
        return edges

    def get_ip(self):
        edge_p = self.read()
        print "type %s %s " % (edge_p.type, edge_p)
        if isinstance(edge_p, NSXEdgeSchema):
            edgeIP = edge_p.vnics[0].addressGroups[0].primaryAddress
        else:
            if edge_p.mgmtInterface.addressGroups[0].primaryAddress is not None:
                edgeIP = edge_p.mgmtInterface.addressGroups[0].primaryAddress
            else:
                edgeIP = edge_p.vnics[0].addressGroups[0].primaryAddress
        return edgeIP

    def appliance_action(self, desired_action):
        schema_object = None
        self.log.debug("Action to be performed on edge is %s" % desired_action)
        if desired_action is not None:
           self.set_create_endpoint("edges/" + self.id + "?action=" + desired_action)
           result_obj = super(Edge, self).create(schema_object)
        # Reseting the create_endpoint
           self.set_create_endpoint("edges")
        return result_obj

    def get_expect_connection(self,vsm_obj):
        exp_connection = connection.Connection(vsm_obj.ip,vsm_obj.username,vsm_obj.password,"None","expect")
        self.exp_connection = exp_connection
        return(self.exp_connection)

    def get_edge_expect_connection(self,edge_username,edge_password):
        edge_ip = self.get_ip()

        pylogger.info("Edge IP = %s" % edge_ip)
        pylogger.info("Edge Default UserName = %s" % edge_username)
        pylogger.info("Edge Default Password = %s" % edge_password)

        edge_exp_connection = connection.Connection(edge_ip,edge_username,edge_password,"None","expect")
        self.edge_exp_connection = edge_exp_connection
        return(self.edge_exp_connection)


    def get_edge_password(self, vsm, edge_id, ste_password):
        expect_client = ExpectClient()

        vsm_conn = vsm.get_connection()
        expect_conn = self.get_expect_connection(vsm_conn)
        expect_client.set_connection(expect_conn)

        expect_client.set_schema_class('no_stdout_schema.NoStdOutSchema')
        expect_client.set_create_endpoint("st e")
        expect_client.set_expect_prompt("Password:")
        cli_data = expect_client.read()

        expect_client.set_schema_class('no_stdout_schema.NoStdOutSchema')
        expect_client.set_create_endpoint(ste_password)
        expect_client.set_expect_prompt("#")
        cli_data = expect_client.read()

        expect_client.set_schema_class('edgepassword_schema.EdgePasswordSchema')
        expect_client.set_create_endpoint("/home/secureall/secureall/sem/WEB-INF/classes/GetSpockEdgePassword.sh")

        """ Parse for following line using expect
        Edge root password:
             edge-41    -> 3OON9pVGZ+mVh0

        OR

        Edge root password:
          No Edge is deployed so far
        """
        expect_client.set_expect_prompt(['Edge root password:\s*(.*)\s+\->\s+(.*)', 'Edge root password:\s*No Edge is deployed so far'])
        cli_data = expect_client.read()

        edge_entry_list = cli_data.table
        if (len(edge_entry_list) == 0):
           pylogger.info("No edge entry found in table")
           return "FAILURE"

        for i in range(len(edge_entry_list)):
            edgeID = edge_entry_list[i].edge
            pylogger.info("EdgeID found in the table is %s" % edgeID)
            if edge_id == edge_entry_list[i].edge:
                edgePassword = edge_entry_list[i].password
                pylogger.info("EdgeID = %s " % edgeID)
                pylogger.info("EdgePassword = %s " % edgePassword)
                return edgePassword

    def execute_edge_cli(self, command, edge_username, edge_password, schema_key):
        expect_client = ExpectClient()

        expect_conn = self.get_edge_expect_connection(edge_username, edge_password)
        expect_client.set_connection(expect_conn)

        edge_id = self.id
        pylogger.info("Edge-ID = %s" % edge_id)
        pylogger.info("Edge Schema key = %s" % schema_key)
        vshield_edge_prompt = "vShield-"+ edge_id + "-0>"
        schema_class = self.get_schema_class(schema_key)
        pylogger.info("Edge Schema class = %s" % schema_class)
        expect_client.set_schema_class(schema_class)
        expect_client.set_create_endpoint(command)
        expect_client.set_expect_prompt(['byte*', vshield_edge_prompt])
        cli_output = expect_client.read('READ_UNTIL_PROMPT')
        pylogger.info("CLI output = %s" % cli_output)

        if cli_output == None:
           return "FAILURE"

        cli_pydict = cli_output.get_py_dict_from_object()
        pylogger.info("CLI OUTPUT PYDict = %s" % cli_pydict)
        return cli_pydict

    def get_schema_class(self, schema_key):
        schema_class_lookup = {
            'ospf' : "edge_ospf_cli_schema.EdgeCliOspfSchema",
            'dhcp' : "edge_dhcp_cli_schema.EdgeDhcpCliSchema"
        }
        return schema_class_lookup[schema_key]

    def get_globalConfigRevision(self):
        edge_object = super(Edge, self).read()
        return edge_object.globalConfigRevision

    def get_name(self):
        edge_object = super(Edge, self).read()
        return edge_object.name

    def get_edge(self):
        edges = self.query()
        for edgeSummary in edges.edgePage.list_schema:
            if edgeSummary.objectId == self.id:
                return edgeSummary

        return common.status_codes.FAILURE

    def get_edge_version(self, server_dict, edge_ha_index="0", get_edge_version=None):
        pylogger.info("Getting Edge Version using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/" + self.id + "/appliances/" + edge_ha_index + "?action=execute"
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = 'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        py_dict = {
            'cmdstr': 'show version'
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)

        result_obj = self.create(schema_obj)

        temp_reponse_data = result_obj[0].response_data
        pylogger.debug("Response Data from API: %s ", temp_reponse_data)

        lines = temp_reponse_data.splitlines()
        server_dict = dict()

        server_dict['name'] = lines[0].split(":")[-1].strip()
        server_dict['version'] = lines[1].split(":")[-1].strip()
        server_dict['kernel'] = lines[3].split(":")[-1].strip()
        return server_dict

    def get_ip_forwarding(self, server_dict, edge_ha_index="0", get_ip_forwarding=None):
        pylogger.info("Getting Edge IP Forwarding using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/" + self.id + "/appliances/" + edge_ha_index + "?action=execute"
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = 'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        py_dict = {
            'cmdstr': 'show ip forwarding'
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)

        result_obj = self.create(schema_obj)

        PARSER = "raw/horizontalTable"
        header_keys = ['Code', 'Network', 'Via', 'NextHop', 'VnicName']  # noqa

        # No. of Header lines to be skipped from output
        skip_head = 2

        raw_payload = result_obj[0].response_data

        pylogger.debug("Response Data from API: %s ", raw_payload)

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        raw_payload = data_parser.marshal_raw_data(raw_payload, 'is directly connected,','isdirectlyconnected NULL')

        # Specify the Header keys that we want to insert to the output
        mod_raw_data = data_parser.insert_header_to_raw_data(raw_payload, header_keys=header_keys, skip_head=skip_head)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data, header_keys=header_keys, skip_head=skip_head, expect_empty_fields=False)

        return pydict

    def get_ip_route(self, server_dict, edge_ha_index="0", get_ip_route=None):
        pylogger.info("Getting Edge IP Route using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/" + self.id + "/appliances/" + edge_ha_index + "?action=execute"
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = 'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        py_dict = {
            'cmdstr': 'show ip route'
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)

        result_obj = self.create(schema_obj)

        PARSER = "raw/horizontalTable"
        header_keys = ['Code', 'Network', 'AdminDist_Metric', 'Via', 'NextHop']

        # No. of Header lines to be skipped from output
        skip_head = 6

        raw_payload = result_obj[0].response_data

        pylogger.debug("Response Data from API: %s ", raw_payload)

        #---------------------------------------------------------------
        # If the raw_payload contains OSPF data we have modify the header
        # and insert NUL element at the second place to parse the data properly
        #
        #
        # C       3.3.3.0/24           [0/0]         via 3.3.3.1
        # O   E2  4.4.4.0/24           [110/0]       via 10.10.10.2   ----> this addition requires below change # noqa
        # C       10.10.10.0/24        [0/0]         via 10.10.10.1
        # O       10.10.10.0/24        [0/0]         via 10.10.10.1
        #
        # After parsing the output will be, Inserting NULL into the second field
        #
        # C   NULL 3.3.3.0/24           [0/0]         via 3.3.3.1
        # O   E2   4.4.4.0/24           [110/0]       via 10.10.10.2
        # C   NULL 10.10.10.0/24        [0/0]         via 10.10.10.1
        # O   NULL 10.10.10.0/24        [0/0]         via 10.10.10.1
        #
        #---------------------------------------------------------------
        if raw_payload.__contains__("O"):
            include_lines = []
            header_keys = ['Code', 'OSPF_ExternalType' , 'Network', 'AdminDist_Metric', 'Via', 'NextHop']
            lines = raw_payload.strip().split("\n")

            for line in lines[:skip_head]:
                include_lines.append(line)

            for line in lines[skip_head:]:
                if (line.strip() != ""):
                    templine = line.split()
                    pattern = '[A-Z]+'
                    matched = re.match(pattern,templine[1])
                    if not matched:
                        templine.insert(1,"NULL")
                    templine = " " . join(templine)
                    print templine
                    include_lines.append(templine)
                else:
                    include_lines.append(line)

            include_lines = '\n'. join(include_lines)
            raw_payload  = include_lines

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        mod_raw_data = data_parser.insert_header_to_raw_data(
            raw_payload, header_keys=header_keys, skip_head=skip_head)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data,
                                             header_keys=header_keys,
                                             skip_head=skip_head,
                                             expect_empty_fields=False)

        return pydict

    def get_ip_ospf_neighbor(self, server_dict, edge_ha_index="0",
                             get_ip_ospf_neighbor=None):
        """
        Sample Command output:
          Neigbhor ID         Priority    Address             Dead Time   State
          2.2.2.2             128         192.168.1.50        38          Full/BDR
        """
        PARSER = "raw/horizontalTable"
        pylogger.info("Getting Edge IP OSPF Neighbor using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/%s/appliances/%s?action=execute" \
                       % (self.id, edge_ha_index)
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = \
            'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        py_dict = {
            'cmdstr': 'show ip ospf neighbor'
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)
        result_obj = self.create(schema_obj)
        raw_payload = result_obj[0].response_data
        pylogger.debug("Response Data from API: %s ", raw_payload)

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        # Insert the Header
        skip_head = 1
        header_keys = ['neigbhor_id', 'priority', 'address', 'dead_time', 'state']  # noqa

        mod_raw_data = data_parser.insert_header_to_raw_data(
            raw_payload,
            header_keys=header_keys,
            skip_head=skip_head)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data,
                                             header_keys=header_keys,
                                             skip_head=skip_head,
                                             expect_empty_fields=False)

        pylogger.debug("Get IP OSPF Neighbor returned pydict: %s", pydict)

        return pydict

    def get_ip_ospf_database(self, server_dict, edge_ha_index="0",
                             area_id=None, search_filter=None,
                             get_ip_ospf_database=None):
        """
        Sample Command output:
                     Router Link States (Area  0.0.0.0)

        Link ID           ADV Router        Age           Seq Num        Checksum
        1.1.1.1           1.1.1.1           1686          0x8000002e    0x0000ca16
        2.2.2.2           2.2.2.2           1686          0x80000002    0x0000c83d

                     Network Link States (Area  0.0.0.0)

        Link ID           ADV Router        Age           Seq Num        Checksum
        192.168.1.51      1.1.1.1           1691          0x80000001    0x00001d8f

                     Opaque Area Link States (Area  0.0.0.0)

        Link ID           ADV Router        Age           Seq Num        Checksum
        1.0.0.1           1.1.1.1           551           0x8000002e    0x00002957
        1.0.0.2           1.1.1.1           488           0x8000002e    0x0000be1a
        1.0.0.3           2.2.2.2           1691          0x80000001    0x0000689a

                     Type-7 AS External Link States (Area  0.0.0.51)

        Link ID           ADV Router        Age           Seq Num        Checksum
        10.110.60.0       1.1.1.1           492           0x8000002e    0x000017d8
        172.168.1.0       1.1.1.1           492           0x8000002e    0x0000b496
        192.168.1.0       1.1.1.1           492           0x8000002e    0x0000af87

                     Opaque Area Link States (Area  0.0.0.51)

        Link ID           ADV Router        Age           Seq Num        Checksum
        1.0.0.1           1.1.1.1           551           0x8000002e    0x0000ceab
        1.0.0.2           1.1.1.1           488           0x8000002e    0x0000646e

                     AS External Link States

        Link ID           ADV Router        Age           Seq Num        Checksum
        10.10.10.0        2.2.2.2           1691          0x80000001    0x00003d6f
        10.110.60.0       1.1.1.1           492           0x8000002e    0x000015da
        172.168.1.0       1.1.1.1           492           0x8000002e    0x0000b298
        192.168.1.0       1.1.1.1           492           0x8000002e    0x0000ad89
        192.168.1.0       2.2.2.2           1691          0x80000001    0x0000e976
        """
        PARSER = "raw/horizontalTable"
        pylogger.info("Getting Edge IP OSPF Database using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/%s/appliances/%s?action=execute" \
                       % (self.id, edge_ha_index)
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = \
            'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        py_dict = {
            'cmdstr': 'show ip ospf database'
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)
        result_obj = self.create(schema_obj)

        search_values = ['Summary_NLS', 'RLS', 'NLS', 'OALS', 'Summary_ASB', 'Type7_AS', 'AS_ExternalLink']
        search_filter = area_id['search_filter']
        pylogger.debug("Search Filter: %s ", search_filter)

        if search_filter not in search_values:
            raise ValueError("Invalid search_filter name: %r. Valid searchfilter values are : %r"
                             % (search_filter, search_values))

        area_id = area_id['area_id']
        pylogger.debug("Area ID: %s ", area_id)

        raw_payload = result_obj[0].response_data

        pylogger.debug("Response Data from API: %s ", raw_payload)

        search_dict = {
            'Summary_NLS': 'Summary Network Link States',
            'RLS': 'Router Link States',
            'NLS': 'Network Link States',
            'OALS': 'Opaque Area Link States',
            'Summary_ASB': 'Summary ASB Link States',
            'Type7_AS': 'Type-7 AS External Link States',
            'AS_ExternalLink': 'AS External Link States'
        }

        search_string = search_dict[search_filter] + " (Area  0.0.0." + area_id + ")"
        include_lines = []

        if raw_payload.__contains__(search_string):
            lines = raw_payload.strip().split("\n")

            for i, line in enumerate(lines):
                if line.find(search_string) != -1:
                    i += 1

                    while lines[i].find("Link States") == -1:
                        include_lines.append(lines[i])
                        i += 1

                        if i == len(lines):
                            break

            include_lines = '\n'.join(include_lines)
            raw_payload = include_lines

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        # Specify the Header keys that we want to insert to the output
        skip_head = 1
        header_keys = ['link_id', 'adv_router', 'age', 'seq_num', 'checksum']
        mod_raw_data = data_parser.insert_header_to_raw_data(raw_payload,
                                                             header_keys=header_keys,
                                                             skip_head=skip_head)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data, header_keys=header_keys,
                                             skip_head=skip_head,
                                             expect_empty_fields=False)

        pylogger.debug("Get IP OSPF Database returned pydict: %s", pydict)

        return pydict

    def get_ip_bgp(self, server_dict, edge_ha_index="0", get_ip_bgp=None):
        """
        Sample Output of command show ip bgp:

        Status codes: s - suppressed, d - damped, > - best, i - internal
        Origin codes: i - IGP, e - EGP, ? - incomplete

             Network             Next Hop        Metric  LocPrf  Weight  Origin
        >  100.64.1.0/31       169.0.0.1          0     100   32768     ?
        >  192.168.40.0/24     192.168.50.2       0     100      60     i
        >  192.168.50.0/24     192.168.50.2       0     100      60     i
        >  192.168.60.0/24     169.0.0.1          0     100   32768     ?
        >  192.168.70.0/24     169.0.0.1          0     100   32768     ?
        """

        PARSER = "raw/horizontalTable"
        pylogger.info("Getting Edge IP BGP using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/%s/appliances/%s?action=execute" %(self.id, edge_ha_index)
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = 'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        py_dict = {
            'cmdstr': 'show ip bgp'
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)

        result_obj = self.create(schema_obj)

        header_keys = ['Scode', 'Network', 'NextHop', 'Metric', 'LocPrf', 'Weight',
                       'Origin']

        # No. of Header lines to be skipped from output
        skip_head = 4

        raw_payload = result_obj[0].response_data

        pylogger.debug("Response Data from API: %s ", raw_payload)

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        # Specify the Header keys that we want to insert to the output
        mod_raw_data = data_parser.insert_header_to_raw_data(raw_payload,
                                                             header_keys=header_keys,
                                                             skip_head=skip_head)
        # Get the parsed data
        pydict = data_parser.get_parsed_data(mod_raw_data,
                                             header_keys=header_keys,
                                             skip_head=skip_head,
                                             expect_empty_fields=False)

        pylogger.debug("get_ip_bgp returned pydict: %s", pydict)

        return pydict

    def get_ip_bgp_neighbors(self, server_dict, edge_ha_index="0", get_ip_bgp_neighbors=None):
        """
        CLI output for show ip bgp neighbors

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
        """

        PARSER = "raw/showBgpNeighbors"
        pylogger.info("Getting Edge IP BGP Neighbors using Centralized API")
        edge_ha_index = edge_ha_index['edge_ha_index']
        url_endpoint = "/edges/%s/appliances/%s?action=execute" %(self.id, edge_ha_index)
        self.set_create_endpoint(url_endpoint)
        self.connection.api_header = '/api/4.0'
        self.schema_class = 'edge_centralized_api_cli_schema.EdgeCentralizedApiCliSchema'

        pylogger.debug("URl EndPoint : %s ", url_endpoint)

        endpoint = "show ip bgp neighbors"
        pylogger.debug("Command to be executed: %s", endpoint)

        py_dict = {
            'cmdstr': endpoint
        }

        schema_obj = EdgeCentralizedApiCliSchema(py_dict)
        result_obj = self.create(schema_obj)

        # Execute the command on the Edge VM
        raw_payload = result_obj[0].response_data

        # Get the parser
        data_parser = utilities.get_data_parser(PARSER)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(raw_payload, delimiter=":")
        pylogger.debug("get_ip_bgp_neighbors returned pydict: %s", pydict)

        return pydict



if __name__ == '__main__':
    import base_client
    var = '''
    <edge>
    <datacenterMoid>datacenter-2</datacenterMoid>
    <type>distributedRouter</type>                   <!-- Mandatory to create "distributedRouter" edge. When absent, defaults to "gatewayServices" -->
    <appliances>                                     <!-- Mandatory for "distributedRouter" edge. Atleast one appliance needs to be configured -->
    <applianceSize>compact</applianceSize>
    <appliance>
    <resourcePoolId>resgroup-20</resourcePoolId>
    <datastoreId>datastore-23</datastoreId>
    </appliance>
    </appliances>
    <mgmtInterface>                                   <!-- Mandatory for "distributedRouter" edge -->
    <connectedToId>dvportgroup-38</connectedToId>
    <addressGroups>
    <addressGroup>
    <primaryAddress>10.112.196.165</primaryAddress>
    <subnetMask>255.255.252.0</subnetMask>
    </addressGroup>
    </addressGroups>
    </mgmtInterface>
    <interfaces>                                      <!-- Optional. Can be added later using modular APIs. Upto 999 interfaces supported. -->
    <interface>
    <type>uplink</type>
    <mtu>1500</mtu>
    <isConnected>true</isConnected>
    <addressGroups>                       <!-- Supports one or more addressGroups -->
    <addressGroup>                   <!-- AddressGroup on "distributedRouter" edge can have only primary ipAddresses. Secondary addresses not supported -->
    <primaryAddress>192.168.10.1</primaryAddress>      <!-- "distributedRouter" edge only supports IPv4 addresses -->
    <subnetMask>255.255.255.0</subnetMask>
    </addressGroup>
    </addressGroups>
    <connectedToId>dvportgroup-39</connectedToId>     <!-- "distributedRouter" edge does not support legacy portGroups -->
    </interface>
    <interface>
    <type>internal</type>
    <mtu>1500</mtu>
    <isConnected>true</isConnected>
    <addressGroups>
    <addressGroup>
    <primaryAddress>192.168.20.1</primaryAddress>
    <subnetMask>255.255.255.0</subnetMask>
    </addressGroup>
    </addressGroups>
    <connectedToId>dvportgroup-40</connectedToId>
    </interface>
    </interfaces>
    </edge>
    '''
    vsm_obj = VSM("10.110.28.44:443", "admin", "", "default")
    py_dict = {'datacentermoid': 'datacenter-2', 'type': 'distributedrouter',
               'appliances':
                   {'appliancesize': 'compact',
                    'appliance': [{'resourcepoolid': 'resgroup-8',
                                   'datastoreid': 'datastore-20'}]},
               'mgmtinterface': {'connectedtoid': 'dvportgroup-19'},
    }
    edge_schema = EdgeSchema(py_dict)
    print edge_schema.appliances.appliances[1].resourcePoolId
    print edge_schema.mgmtInterface.connectedToId
    print edge_schema.get_data('xml')
    edge_client = Edge(vsm_obj)
    base_client.bulk_create(edge_client, [py_dict])

    response = '<edge><datacenterMoid>datacenter-2</datacenterMoid><type>distributedRouter</type><appliances><applianceSize>compact</applianceSize><appliance><resourcePoolId>resgroup-20</resourcePoolId><datastoreId>datastore-23</datastoreId></appliance><appliance><resourcePoolId>resgroup-21</resourcePoolId><datastoreId>datastore-23</datastoreId></appliance></appliances><mgmtInterface><connectedToId>dvportgroup-38</connectedToId><addressGroups><addressGroup><primaryAddress>10.112.196.165</primaryAddress><subnetMask>255.255.252.0</subnetMask></addressGroup></addressGroups></mgmtInterface></edge>'

    edge_schema = EdgeSchema()
    edge_schema.set_data(response, 'xml')

    py_dict = {'ipAddress': '10.115.175.237', 'userName': 'root', 'password': 'vmware'}
    vsm_obj = VSM("10.115.175.238:443", "admin", "default")

    edge_create_controller = Edge(vsm_obj)
    edge_schema = EdgeSchema()
    edge_schema.datacenterMoid = 'datacenter-2'
    edge_schema.type = 'distributedRouter'
    edge_schema.appliances.applianceSize = 'compact'

    appliance_schema = ApplianceSchema()
    appliance_schema.datastoreId = 'datastore-11'
    appliance_schema.resourcePoolId = 'resgroup-8'
    edge_schema.appliances.appliances.append(appliance_schema)

    add_grp = AddressGroupSchema()
    add_grp.primaryAddress = '192.168.1.1'
    add_grp.subnetMask = '255.255.255.0'
    edge_schema.mgmtInterface.addressGroups.append(add_grp)

    intf_schema = InterfaceSchema()
    intf_schema.type = 'internal'
    intf_schema.mtu = '1500'
    intf_schema.isConnected = 'true'

    edge_schema.interfaces.interfaces.append(intf_schema)

    print edge_schema.get_data('xml')

    response = '<edge><datacenterMoid>datacenter-2</datacenterMoid><type>distributedRouter</type><appliances><applianceSize>compact</applianceSize><appliance><resourcePoolId>resgroup-20</resourcePoolId><datastoreId>datastore-23</datastoreId></appliance><appliance><resourcePoolId>resgroup-21</resourcePoolId><datastoreId>datastore-23</datastoreId></appliance></appliances><mgmtInterface><connectedToId>dvportgroup-38</connectedToId><addressGroups><addressGroup><primaryAddress>10.112.196.165</primaryAddress><subnetMask>255.255.252.0</subnetMask></addressGroup></addressGroups></mgmtInterface></edge>'

    edge_schema.set_data(response, 'xml')
    print edge_schema.appliances.appliances[0].resourcePoolId
    print edge_schema.appliances.appliances[1].resourcePoolId
    print edge_schema.mgmtInterface.addressGroups[0].primaryAddress

    vsm_obj = VSM("10.112.110.180:443", "admin", "default")
    py_dict = {'datacentermoid': 'datacenter-2', 'type': 'distributedrouter',
               'appliances':
                   {'appliancesize': 'compact',
                    'appliance': [{'resourcepoolid': 'resgroup-8',
                                   'datastoreid': 'datastore-20'}]},
               'mgmtinterface': {'connectedtoid': 'dvportgroup-19'},
    }
    edge_schema = EdgeSchema(py_dict)
    print edge_schema.appliances.appliances[1].resourcePoolId
    print edge_schema.mgmtInterface.connectedToId
