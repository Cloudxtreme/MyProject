import json
import ConfigParser
import io
import vmware.common as common
import vmware.common.errors as errors
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
    EXPECT = ['bytes*', '>']

    @classmethod
    def get_arp_table(cls, client_object, switch_vni=None):
        cmd = "get logical-switch %s arp-table" % switch_vni
        arp_table_attributes_map = {
            'connection-id': 'connection_id',
            'ip': 'adapter_ip',
            'mac': 'adapter_mac'
        }
        return client_object.execute_cmd_get_schema(
            cmd, arp_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            arp_table_schema.ARPTableSchema, expect=cls.EXPECT,
            skip_tail=1)

    @classmethod
    def get_mac_table(cls, client_object, switch_vni=None):
        cmd = "get logical-switch %s mac-table" % switch_vni
        mac_table_attributes_map = {
            'mac':      'adapter_mac',
            'vtep-ip':  'adapter_ip'
        }
        return client_object.execute_cmd_get_schema(
            cmd, mac_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            mac_table_schema.MACTableSchema, expect=cls.EXPECT,
            skip_tail=1)

    @classmethod
    def get_vtep_table(cls, client_object, switch_vni=None,
                       host_switch_name=None):
        _ = host_switch_name
        cmd = ("get logical-switch %s vtep" % switch_vni)
        vtep_table_attributes_map = {
            'ip': 'adapter_ip'
        }
        return client_object.execute_cmd_get_schema(
            cmd, vtep_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            vtep_table_schema.VtepTableSchema, expect=cls.EXPECT,
            skip_tail=1)

    @classmethod
    def get_vni_table(cls, client_object, switch_vni=None):
        cmd = "get logical-switch %s" % switch_vni
        vni_table_attributes_map = {
            'bum-replication': 'bum_replication',
            'arp-proxy': 'arp_proxy'
        }
        return client_object.execute_cmd_get_schema(
            cmd, vni_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            vni_table_schema.VNITableSchema, expect=cls.EXPECT,
            skip_tail=1)

    @classmethod
    def get_stats_table(cls, client_object, switch_vni=None):
        cmd = "get logical-switch %s stats" % switch_vni
        vni_stats_table_attributes_map = {
            'update.arp': 'update_arp',
            'query.arp': 'query_arp',
            'query.arp.miss': 'query_arp_miss'
        }
        return client_object.execute_cmd_get_schema(
            cmd, vni_stats_table_attributes_map, cls.VERTICAL_PARSER_TYPE,
            vni_stats_table_schema.VNIStatsTableSchema, expect=cls.EXPECT)

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
        cmd = "get logical-switch %s connection-table" % switch_vni
        attributes_map = {'host-ip': 'adapter_ip'}
        return client_object.execute_cmd_get_schema(
            cmd, attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            connection_table_schema.ConnectionTableSchema,
            expect=cls.EXPECT, skip_tail=1)

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
            if (((vni_entry.vni is not None) and
                 (int(vni_entry.vni) == int(switch_vni)))):
                # XXX(Salman): This assumes that the controller's management IP
                # used to bootstrap it with the manager is the same as the IP
                # used by the VDNet to talk to the controller -- This may not
                # always hold.
                if vni_entry.controller == client_object.ip:
                    return True
        return False

    @classmethod
    def get_logical_switches(cls, client_object, switches=None, **kwargs):
        cmd = "start debugging"
        connection = client_object.connection
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])
        py_dict = {}
        py_dict_node = {}
        node_data = []
        for switche in switches:
            uuid = switche.id_
            cmd = "get mediator lookup %s" % uuid
            result = connection.request(command=cmd,
                                        expect=['bytes*', '>'])
            parsed_data = {}
            data = []
            lines = result.response_data.strip().split("\n")
            if ((len(lines) > 0) and
                ((lines[0].upper().find("ERROR") > 0) or
                 (lines[0].upper().find("NOT FOUND") > 0) or
                 (len(lines) == 1 and lines[0].strip() == ""))):
                return parsed_data
            for line in lines:
                data.append(line.rstrip())
            fina_data = data[0].replace("'", '')
            # output as below:
            # [{"vni": {"vni": 13704},"replication_mode": {"mode": "UNICAST_MTEP"},"transport_binding": {"type": "VXSTT"}}]  # noqa

            switch_entries = json.loads(fina_data)
            for switch_entry in switch_entries:
                vni = switch_entry["vni"]["vni"]
                mode = switch_entry["replication_mode"]["mode"].lower()
                if "source" in mode:
                    replication_mode = "source"
                if "mtep" in mode:
                    replication_mode = "mtep"
                bind_type = switch_entry["transport_binding"]["type"].lower()
                py_dict_node = {"switch_vni": vni,
                                "replication_mode": replication_mode,
                                "binding_type": bind_type}
            if py_dict_node:
                node_data.append(py_dict_node)
            py_dict_node = {}

        py_dict.update({"table": node_data})
        return py_dict

    @classmethod
    def get_entry_count(cls, client_object, **kwargs):
        cmd = "start debugging"
        connection = client_object.connection
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])

        cmd = "get mediator count"
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])
        py_dict = {}
        parsed_data = {}
        data = []
        lines = result.response_data.strip().split("\n")
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return parsed_data
        for line in lines:
            data.append(line.rstrip())

        # Output as below:
        # ['LOG_ROUTER = 0', 'LOG_ROUTER_PORT = 0', 'TRANSPORT_NODE = 0', 'DHCP_RELAY = 0', 'LOG_SWITCH = 0', 'LOG_SWITCH_PORT = 0', 'Total entries 0', '', 'wdc-vsphere-cf-fvt-137-dhcp211']  # noqa

        data.insert(0, '[entry]')
        data = '\n'.join(data)

        """
        ... Output as below
        ... [entry]
        ... LOG_ROUTER = 0
        ... LOG_ROUTER_PORT = 0
        ... TRANSPORT_NODE = 2
        ... DHCP_RELAY = 0
        ... LOG_SWITCH = 0
        ... LOG_SWITCH_PORT = 0
        """

        config = ConfigParser.RawConfigParser(allow_no_value=True)
        config.readfp(io.BytesIO(data))

        logical_router = config.get("entry", "LOG_ROUTER")
        logical_router_port = config.get("entry", "LOG_ROUTER_PORT")
        transport_node = config.get("entry", "TRANSPORT_NODE")
        dhcp_relay = config.get("entry", "DHCP_RELAY")
        logical_switch = config.get("entry", "LOG_SWITCH")
        logical_switch_port = config.get("entry", "LOG_SWITCH_PORT")

        py_dict = {"logical_router": int(logical_router),
                   "logical_router_port": int(logical_router_port),
                   "transport_node": int(transport_node),
                   "dhcp_relay": int(dhcp_relay),
                   "logical_switch": int(logical_switch),
                   "logical_switch_port": int(logical_switch_port)}
        return py_dict

    @classmethod
    def get_full_sync_count(cls, client_object, **kwargs):
        cmd = "start debugging"
        connection = client_object.connection
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])

        cmd = "get mediator fullsync"
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])
        py_dict = {}
        parsed_data = {}
        data = []
        lines = result.response_data.strip().split("\n")
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return parsed_data
        for line in lines:
            data.append(line.rstrip())

        # Output as below:
        # ['FullSyncProgress  = No sync', 'Config session id = cc8f3af5-5f9b-4c3c-96da-07b643091548', 'Number of syncs = 5', 'Config sequence num = 1330', 'CCP id  = 6c10ff14-34c9-40ab-8bb0-8afac4c57b33', 'wdc-vsphere-cf-fvt-138-dhcp176']  # noqa

        data.insert(0, '[entry]')
        data = '\n'.join(data)

        """
        ... Output as below
        ... [entry]
        ... FullSyncProgress  = No sync
        ... Config session id = cc8f3af5-5f9b-4c3c-96da-07b643091548
        ... Number of syncs = 3
        ... Config sequence num = 1330
        ... CCP id  = 66e5198d-6514-40df-84dd-d8c18131895d
        """
        config = ConfigParser.RawConfigParser(allow_no_value=True)
        config.readfp(io.BytesIO(data))

        fullsync_progress = config.get("entry", "FullSyncProgress")
        config_session_id = config.get("entry", "Config session id")
        number_syncs = config.get("entry", "Number of syncs")
        config_sequence_num = config.get("entry", "Config sequence num")
        ccp_id = config.get("entry", "CCP id")

        py_dict = {"fullsync_progress": fullsync_progress,
                   "config_session_id": config_session_id,
                   "number_syncs": int(number_syncs),
                   "config_sequence_num": int(config_sequence_num),
                   "ccp_id": ccp_id}
        return py_dict

    @classmethod
    def get_full_sync_diff(cls, client_object,
                           before_test_full_sync_count, **kwargs):
        ENTRY = 'enty'
        NUMBER_OF_SYNCS = 'Number of syncs'
        FULL_SYNC_DIFF = 'full_sync_diff'
        cmd = "start debugging"
        connection = client_object.connection
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])

        cmd = "get mediator fullsync"
        result = connection.request(command=cmd,
                                    expect=['bytes*', '>'])

        data = []
        lines = result.response_data.splitlines()
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            pylogger.error("Failed to run CLI: %s"
                           % lines)
            raise errors.Error(status_code=common.status_codes.FAILURE,
                               reason="Failed to execute CLI")

        for line in lines:
            data.append(line.rstrip())

        data.insert(0, '[%s]' % ENTRY)
        data = '\n'.join(data)

        config = ConfigParser.RawConfigParser(allow_no_value=True)
        config.readfp(io.BytesIO(data))

        number_syncs = config.get(ENTRY, NUMBER_OF_SYNCS)
        full_sync_diff = int(number_syncs) - int(before_test_full_sync_count)

        py_dict = {FULL_SYNC_DIFF: int(full_sync_diff)}
        return py_dict
