import vmware.common.global_config as global_config
import vmware.interfaces.switch_interface as switch_interface
import vmware.schema.controller.connection_table_schema as connection_table_schema  # noqa
import vmware.schema.switch.arp_table_schema as arp_table_schema
import vmware.schema.switch.mac_table_schema as mac_table_schema
import vmware.schema.switch.vni_table_schema as vni_table_schema
import vmware.schema.switch.vni_stats_table_schema as vni_stats_table_schema
import vmware.schema.switch.vtep_table_schema as vtep_table_schema

pylogger = global_config.pylogger


class NSX70SwitchImpl(switch_interface.SwitchInterface):
    HORIZONTAL_PARSER_TYPE = "raw/horizontalTable"
    VERTICAL_PARSER_TYPE = "raw/vnistatsverticalTable"

    @classmethod
    def get_arp_table(cls, client_object, switch_vni=None):
        cmd = ("/opt/vmware/ccp/bin/scripts/vnet_client.py "
               "show logical-switches arp-table %s" % switch_vni)
        arp_table_attributes_map = {
            'connection-id': 'connection_id',
            'ip': 'adapter_ip',
            'mac': 'adapter_mac'
        }
        return client_object.execute_cmd_get_schema(
            cmd, arp_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            arp_table_schema.ARPTableSchema)

    @classmethod
    def get_mac_table(cls, client_object, switch_vni=None):
        cmd = ("/opt/vmware/ccp/bin/scripts/vnet_client.py "
               "show logical-switches mac-table %s" % switch_vni)
        mac_table_attributes_map = {
            'mac': 'adapter_mac',
            'vtep-ip': 'adapter_ip'
        }
        return client_object.execute_cmd_get_schema(
            cmd, mac_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            mac_table_schema.MACTableSchema)

    @classmethod
    def get_vtep_table(cls, client_object, switch_vni=None,
                       host_switch_name=None):
        _ = host_switch_name
        cmd = ("/opt/vmware/ccp/bin/scripts/vnet_client.py "
               "show logical-switches vtep-table %s" % switch_vni)
        vtep_table_attributes_map = {
            'ip': 'adapter_ip'
        }
        return client_object.execute_cmd_get_schema(
            cmd, vtep_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            vtep_table_schema.VtepTableSchema)

    @classmethod
    def get_vni_table(cls, client_object, switch_vni=None):
        cmd = ("/opt/vmware/ccp/bin/scripts/vnet_client.py "
               "show logical-switches vni %s" % switch_vni)
        vni_table_attributes_map = {
            'bum-replication': 'bum_replication',
            'arp-proxy': 'arp_proxy'
        }
        return client_object.execute_cmd_get_schema(
            cmd, vni_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            vni_table_schema.VNITableSchema)

    @classmethod
    def get_stats_table(cls, client_object, switch_vni=None):
        cmd = ("/opt/vmware/ccp/bin/scripts/vnet_client.py "
               "show logical-switches vni-stats %s" % switch_vni)
        vni_stats_table_attributes_map = {
            'update.arp': 'update_arp',
            'query.arp': 'query_arp'
        }
        return client_object.execute_cmd_get_schema(
            cmd, vni_stats_table_attributes_map, cls.VERTICAL_PARSER_TYPE,
            vni_stats_table_schema.VNIStatsTableSchema)

    @classmethod
    def get_connection_table(cls, client_object, switch_vni=None,
                             get_connection_table=None):
        """
        Returns the IP addresses of the hosts that reported themselves to the
        controller as being part of a given VNI.

        @type switch_vni: str
        @param switch_vni: VNI of the switch.
        @rtype: ConnectionTableSchema
        @return: Returns the connection table schema object.
        """
        cmd = ("/opt/vmware/ccp/bin/scripts/vnet_client.py "
               "show logical-switches connection-table %s" % switch_vni)
        attributes_map = {'host-ip': 'adapter_ip'}
        return client_object.execute_cmd_get_schema(
            cmd, attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            connection_table_schema.ConnectionTableSchema)

    @classmethod
    def is_master_for_vni(cls, client_object, switch_vni=None):
        vni_table_schema_object = cls.get_vni_table(
            client_object, switch_vni=switch_vni)
        vni_entry_list = vni_table_schema_object.table
        if not vni_entry_list:
            pylogger.debug("Warning: Controller %r does not contain VNI table "
                           "info" % client_object)
            return False
        for vni_entry in vni_entry_list:
            if int(vni_entry.vni) == int(switch_vni):
                if vni_entry.controller == client_object.ip:
                    return True
        return False
