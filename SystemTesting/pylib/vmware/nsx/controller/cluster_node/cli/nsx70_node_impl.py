import vmware.common.global_config as global_config
import vmware.interfaces.node_interface as node_interface
import vmware.schema.clusternode.cluster_node_schema as cluster_node_schema  # noqa
import vmware.common.utilities as utilities


pylogger = global_config.pylogger


class NSX70NodeImpl(node_interface.NodeInterface):
    CLUSTERNODE_PARSER_TYPE = "raw/clusternodes"
    HORIZONTAL_PARSER_TYPE = "raw/horizontalTable"

    @classmethod
    def get_cluster_node(cls, client_object, **kwargs):
        cmd = "get control-cluster status"
        cluster_node_table_attributes_map = {
            'is master': 'is_master',
            'in majority': 'in_majority',
            'cluster node': 'cluster_nodes'
        }
        return client_object.execute_cmd_get_schema(
            cmd, cluster_node_table_attributes_map,
            cls.CLUSTERNODE_PARSER_TYPE,
            cluster_node_schema.ClusterNodesSchema, expect=['bytes*', '>'])

    @classmethod
    def get_controller_vif(cls, client_object, **kwargs):
        if kwargs['vif_id'] is None:
            raise ValueError('vif_id parameter is missing')

        vif_uuid = kwargs['vif_id']
        cmd = "get vif %s" % vif_uuid
        cluster_node_vifs_table_attributes_map = {
            'vif': 'vif_id',
            'logswitchport-id': 'port_id',
            'transportnode-id': 'transportnode_id',
            'transportnode-ip': 'transportnode_ip'
        }

        return client_object.execute_cmd_get_schema(
            cmd, cluster_node_vifs_table_attributes_map,
            cls.HORIZONTAL_PARSER_TYPE,
            cluster_node_schema.ClusterNodeVIFsSchema,
            expect=['bytes*', '>'])

    @classmethod
    def get_cluster_startupnodes(cls, client_object, **kwargs):
        cmd = "get control-cluster startup-nodes"
        expect = ['bytes*', '>']
        raw_data = client_object.connection.request(cmd, expect).response_data

        header_keys = ['controller_ip']
        data_parser = utilities.get_data_parser(cls.HORIZONTAL_PARSER_TYPE)
        mod_raw_data = data_parser.insert_header_to_raw_data(
            raw_data, header_keys=header_keys)

        mapped_pydicts = utilities.parse_data_map_attributes(
            mod_raw_data, cls.HORIZONTAL_PARSER_TYPE, attribute_map=None)

        return cluster_node_schema.ClusterStartupNodesSchema(mapped_pydicts)

    @classmethod
    def get_cluster_managers(cls, client_object, **kwargs):
        cmd = "get managers"
        expect = ['bytes*', '>']
        raw_data = client_object.connection.request(cmd, expect).response_data

        mod_raw_data = raw_data.replace(':', ' ')
        header_keys = ['ip', 'port', 'thumbprint']
        data_parser = utilities.get_data_parser(cls.HORIZONTAL_PARSER_TYPE)
        mod_raw_data = data_parser.insert_header_to_raw_data(
            mod_raw_data, header_keys=header_keys)

        mapped_pydicts = utilities.parse_data_map_attributes(
            mod_raw_data,
            cls.HORIZONTAL_PARSER_TYPE,
            attribute_map=None,
            skip_tail=1)

        return cluster_node_schema.ClusterManagerNodesSchema(mapped_pydicts)
