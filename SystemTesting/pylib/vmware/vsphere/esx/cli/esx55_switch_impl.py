import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.switch_interface as switch_interface
import vmware.schema.switch.arp_table_schema as arp_table_schema
import vmware.schema.switch.logical_switch_schema as logical_switch_schema
import vmware.schema.switch.mac_table_schema as mac_table_schema
import vmware.schema.switch.vtep_table_schema as vtep_table_schema

pylogger = global_config.pylogger


class ESX55SwitchImpl(switch_interface.SwitchInterface):
    VERTICAL_PARSER_TYPE = "raw/verticalTable"
    NETVDL2_LOGICALSWITCH_TYPE = "raw/netvdl2LogicalSwitch"
    VDL2_MAC_TABLE_TYPE = 'raw/vdl2MacTable'
    VDL2_ARP_TABLE_TYPE = 'raw/vdl2ArpTable'
    VDL2_VTEP_TABLE_TYPE = 'raw/vdl2VtepTable'
    DEFAULT_HOST_SWITCH_NAME = 'nsxvswitch'

    @classmethod
    # TODO(jschmidt): take hosts_switch_name as input param, adjust interface
    def get_arp_table(cls, client_object, switch_vni=None):
        command = "net-vdl2 -M arp -s %s -n %s" % \
            (cls.DEFAULT_HOST_SWITCH_NAME, switch_vni)
        pylogger.info("Getting arp table command %s" % command)
        arp_table_attributes_map = {'ip': 'adapter_ip',
                                    'mac': 'adapter_mac'}
        return client_object.execute_cmd_get_schema(
            command, arp_table_attributes_map, cls.VDL2_ARP_TABLE_TYPE,
            arp_table_schema.ARPTableSchema)

    @classmethod
    # TODO(jschmidt): take hosts_switch_name as input param, adjust interface
    def get_mac_table(cls, client_object, switch_vni=None):
        command = "net-vdl2 -M mac -s %s -n %s" % \
            (cls.DEFAULT_HOST_SWITCH_NAME, switch_vni)
        pylogger.info("Getting MAC table command %s" % command)
        mac_table_attributes_map = {'inner mac': 'adapter_mac',
                                    'outer ip': 'adapter_ip'}
        return client_object.execute_cmd_get_schema(
            command, mac_table_attributes_map, cls.VDL2_MAC_TABLE_TYPE,
            mac_table_schema.MACTableSchema)

    @classmethod
    def get_logical_switch(cls, client_object, get_logical_switch=None):
        command = "net-vdl2 -l"
        pylogger.info("Getting logical switch information by %r" % command)
        vdl2_table_attributes_map = {
            'controller': 'controller_ip',
            'controllerstatus': 'controller_status',
            'logical network': 'switch_vni'
        }
        return client_object.execute_cmd_get_schema(
            command, vdl2_table_attributes_map, cls.NETVDL2_LOGICALSWITCH_TYPE,
            logical_switch_schema.LogicalSwitchSchema)

    @classmethod
    def get_vtep_table(cls, client_object, switch_vni=None,
                       host_switch_name=None):
        if host_switch_name is None:
            host_switch_name = cls.DEFAULT_HOST_SWITCH_NAME
        command = "net-vdl2 -M vtep -s %s -n %s" % \
            (host_switch_name, switch_vni)
        pylogger.info("Getting vtep table command %s" % command)
        vtep_table_attributes_map = {'segment id': 'segmentid',
                                     'vtep ip': 'adapter_ip',
                                     'is mtep': 'ismtep'}
        return client_object.execute_cmd_get_schema(
            command, vtep_table_attributes_map, cls.VDL2_VTEP_TABLE_TYPE,
            vtep_table_schema.VtepTableSchema)

    @classmethod
    def set_switch_mtu(cls, client_object, value=1500, vmnic_name='vmnic1'):
        command = "esxcfg-vswitch -l | grep %s | awk '{print $1}'" % vmnic_name
        pylogger.info("getting opaque switch name command %s" % command)
        nvs_name = client_object.connection.request(command).response_data
        nvs_name = nvs_name.strip()
        # successfully executed cmd output should contains opaque switch name
        if nvs_name == "":
            pylogger.error("Error in getting NVS switch command %s" % command)
            return constants.Result.FAILURE.upper()

        command = "esxcfg-vswitch --mtu %s %s" % (value, nvs_name)
        pylogger.info("setting opaque switch %s mtu to %s" % (nvs_name, value))
        raw_data = client_object.connection.request(command).response_data
        raw_data = raw_data.strip()
        # successfully executed cmd output should contains nothing
        if raw_data != "":
            pylogger.error("Error in setting opaque switch %s mtu to %s" %
                           (nvs_name, value))
            return constants.Result.FAILURE.upper()

        mtu = cls.get_switch_mtu(client_object, vmnic_name)
        if value != mtu:
            pylogger.error("Getting MTU %s is not same as setted MTU %s" %
                           (mtu, value))
            return constants.Result.FAILURE.upper()
        return constants.Result.SUCCESS.upper()

    @classmethod
    def get_switch_mtu(cls, client_object, vmnic_name='vmnic1'):
        command = "esxcfg-vswitch -l | grep %s | awk '{print $1}'" % vmnic_name
        pylogger.info("getting opaque switch name command %s" % command)
        nvs_name = client_object.connection.request(command).response_data
        nvs_name = nvs_name.strip()
        if nvs_name == "":
            pylogger.error("Error in getting opaque switch mtu command %s" %
                           command)
            return constants.Result.FAILURE.upper()

        command = "net-dvs -l | grep %s -B 5 | grep mtu | awk '{print $3}'" % \
                  nvs_name
        pylogger.info("getting opaque switch %s mtu command" % nvs_name)
        mtu = client_object.connection.request(command).response_data.strip()
        if mtu == "":
            pylogger.error("Error in getting opaque switch %s mtu" % nvs_name)
            return constants.Result.FAILURE.upper()
        return mtu

    @classmethod
    def delete_vdr_port(cls, client_object, switch_name):
        """
        Delete VDR port from logical switch.
        """
        switch_name = utilities.get_default(switch_name, 'nsxvswitch')
        command = "net-dvs -D -p vdrPort %s" % switch_name
        try:
            client_object.connection.request(command)
        except Exception, error:
            pylogger.error("Failed to delete vdr port from %s: %r" %
                           (switch_name, error))
            raise
