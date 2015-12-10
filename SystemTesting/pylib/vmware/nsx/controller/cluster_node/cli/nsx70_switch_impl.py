import vmware.common.global_config as global_config
import vmware.interfaces.switch_interface as switch_interface
import vmware.schema.clusternode.cluster_node_schema as cluster_node_schema  # noqa


pylogger = global_config.pylogger


class NSX70SwitchImpl(switch_interface.SwitchInterface):
    HORIZONTAL_PARSER_TYPE = "raw/horizontalTable"

    @classmethod
    def get_switch_ports(cls, client_object, **kwargs):
        if kwargs['switch_id'] is None:
            raise ValueError('switch_id parameter is missing')

        switch_id = kwargs['switch_id']
        cmd = "get logical-switch %s ports " % switch_id
        logicalswitchports_table_attributes_map = {
            'vif': 'vif_id',
            'logswitch-id': 'switch_id',
            'logswitchport-id': 'port_id'
        }

        return client_object.execute_cmd_get_schema(
            cmd, logicalswitchports_table_attributes_map,
            cls.HORIZONTAL_PARSER_TYPE,
            cluster_node_schema.LogicalSwitchPortsSchema,
            expect=['bytes*', '>'])
