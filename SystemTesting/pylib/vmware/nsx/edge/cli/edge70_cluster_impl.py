import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.cluster_interface as cluster_interface
import vmware.schema.gateway.show_edge_cluster_status_schema as\
    show_edge_cluster_status_schema
import vmware.parsers.horizontal_table_right_aligned_parser as \
    horizontal_table_parser_cluster
pylogger = global_config.pylogger


class Edge70ClusterImpl(cluster_interface.ClusterInterface):

    @classmethod
    def get_cluster_status(cls, client_object, **kwargs):
        '''
            NSXEdge>show edge-cluster status
            Highavailability Status:             Standby
            Highavailability State since:        2014-10-22 17:45:43.559
            Highavailability Unit Id:            0
            Highavailability Unit State:         Down
            Highavailability Admin State:        Up
            Highavailability Running Resources:  None
            Highavailability Active Nodes:       None
            Unit Poll Policy:
               Frequency:                       1     seconds
               Deadtime:                        6     seconds
            Highavailability Services Status:
               Routing Status Channel:          Up
               Routing Status:                  Down
               Healthcheck Config Channel:      Up
               Healthcheck Status Channel:      Up
               Highavailability Healthcheck Status:
            This unit [0]: Down
               Peer unit [1]: Down
                  Session via vNic_0: 10.110.63.98:10.110.63.47 Down
                  Session via vNic_2: 169.255.255.241:169.255.255.242 Down
               Peer unit [2]: Down
                  Session via vNic_0: 10.110.63.98:10.110.63.240 Down
                  Session via vNic_2: 169.255.255.241:169.255.255.243 Down
        '''

        cli_command = "show edge-cluster status"
        PARSER = "raw/showedgeclusterstatus"
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, cli_command, PARSER, EXPECT_PROMPT, ' ')

        client_object.connection.close()

        show_edge_cluster_status_schema_object = show_edge_cluster_status_schema.\
            ShowEdgeClusterStatusSchema(mapped_pydict)
        pylogger.info("show edge-cluster status command output : %s"
                      % show_edge_cluster_status_schema_object.__dict__)
        return show_edge_cluster_status_schema_object

    @classmethod
    def get_cluster_history_resource(cls, client_object, **kwargs):
        '''
            NSXEdge> show edge-cluster history resource
                              Time      Running Resources         Active Nodes
            ====================== ====================== ====================
            2015-01-19 18:06:58.76                      0                 0, 1
            2015-01-19 18:06:49.22                   0, 1                    0
        '''

        horizontal_parser = horizontal_table_parser_cluster.\
            HorizontalTableRightAlignedParser()
        cmd = "show edge-cluster history resource"
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']
        header_keys = ['Time', 'Running Resources', 'Active Nodes']

        raw_data = client_object.connection.request(cmd, EXPECT_PROMPT).\
            response_data
        horizontal_data = horizontal_parser.get_parsed_data(
            raw_data, expect_empty_fields=True,
            header_keys=header_keys)['table']

        return Edge70ClusterImpl.get_pydict_from_data(
            horizontal_data, header_keys)

    @classmethod
    def get_cluster_history_state(cls, client_object, **kwargs):
        '''
            NSXEdge> show edge-cluster history state
                              Time      State                 Event      Reason
            ====================== ========== ====================== ==========
            2015-01-19 18:06:49.22     Active    Node State Changed          Up
            2015-01-19 18:04:47.19    Standby        Config Updated      Config
            2015-01-19 18:04:47.19    Offline        Config Updated      Config
            2015-01-19 18:00:55.68   Disabled                  Init        Init
        '''

        horizontal_parser = horizontal_table_parser_cluster.\
            HorizontalTableRightAlignedParser()
        cmd = "show edge-cluster history state"
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']
        header_keys = ['Time', 'State', 'Event', 'Reason']

        raw_data = client_object.connection.request(cmd, EXPECT_PROMPT).\
            response_data
        horizontal_data = horizontal_parser.get_parsed_data(
            raw_data, expect_empty_fields=True,
            header_keys=header_keys)['table']

        return Edge70ClusterImpl.get_pydict_from_data(
            horizontal_data, header_keys)

    @classmethod
    def get_pydict_from_data(cls, horizontal_data=None, header_keys=None):
        '''
            This function will accept data - returned as table entrants
            and header_keys which define the provided table.
            The method processes the above inputs to create a python
            dictionary object readable to the TDS/ YAML scripts.

            @param horizontal_data: data from horizontal table parser.
            @type horizontal_data: table
            @param header_keys: Table keys from calling function.
            @type horizontal_data: list
            @return: Returns the python dictionary object.
            @rtype: pydict
        '''

        py_dicts = []
        for info in horizontal_data:
            py_dict = {}
            for header_key in header_keys:
                py_dict[header_key.lower()] = info[header_key.lower()]
            py_dicts.append(py_dict)
        py_dict = {'table': py_dicts}

        pylogger.info("OUTPUT %s " % py_dict)
        return py_dict
