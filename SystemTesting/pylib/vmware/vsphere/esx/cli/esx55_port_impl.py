import vmware.common.global_config as global_config
import vmware.interfaces.port_interface as port_interface
import vmware.schema.port.port_schema as port_schema
import vmware.schema.port.port_teaming_schema as port_teaming_schema

pylogger = global_config.pylogger


class ESX55PortImpl(port_interface.PortInterface):
    NETDVS_PORT_TYPE = "raw/netdvsPort"
    NETDVS_TEAMING_TYPE = "raw/netdvsTeaming"

    @classmethod
    def get_port_qos_info(cls, client_object, get_port_qos_info=None):
        command = "net-dvs -l"
        pylogger.info("Getting port Qos configuration: %s" % command)
        port_attributes_map = {}
        return client_object.execute_cmd_get_schema(
            command, port_attributes_map, cls.NETDVS_PORT_TYPE,
            port_schema.PortQosInfoTableSchema)

    @classmethod
    def get_port_teaming_info(cls, client_object, get_port_teaming_info=None):
        command = "net-dvs -l"
        pylogger.info("Getting port Teaming configuration: %s" % command)
        port_teaming_map = {}
        return client_object.execute_cmd_get_schema(
            command, port_teaming_map, cls.NETDVS_TEAMING_TYPE,
            port_teaming_schema.PortTeamingInfoTableSchema)
