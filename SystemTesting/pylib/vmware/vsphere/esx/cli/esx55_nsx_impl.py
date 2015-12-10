import vmware.common.global_config as global_config
import vmware.interfaces.nsx_interface as nsx_interface
import vmware.schema.ipfix_table_schema as ipfix_table_schema

pylogger = global_config.pylogger


class ESX55NSXImpl(nsx_interface.NSXInterface):
    IPFIX_TABLE_TYPE = 'raw/flatverticalTable'

    @classmethod
    def get_ipfix_config(cls, client_object, **kwargs):
        """
        Returns the IPFIX configuration from an ESX host obtained using the
        net-dvs command.

        Sample output:
        switch b6 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 05 (etherswitch)
            max ports: 1536
            global properties:
                com.vmware.common.version = 0x64. 0. 0. 0
                    propType = CONFIG
                com.vmware.common.opaqueDvs = true ,    propType = CONFIG
                com.vmware.common.alias = xxx ,     propType = CONFIG
                com.vmware.extraconfig.opaqueDvs.status = up ,propType = CONFIG
                com.vmware.common.uplinkPorts:
                    uplink.1
                    propType = CONFIG
                com.vmware.etherswitch.ipfix:
                    idle timeout = 60 seconds
                    active timeout = 60 seconds
                    sampling rate = 1
                    collector = 127.0.2.121:80
                    internal flows only = false
                    propType = CONFIG

        @type client_object: BaseClient.
        @param client_object: Used to pass commands to the host.
        @rtype: ipfix_table_schema.IPFIXTableSchema.
        @return: Returns the IPFIXTableSchema object.
        """
        command = 'net-dvs'
        pylogger.info("Getting IPFIX configuration using: %s" % command)
        ipfix_table_attributes_map = {
            'idle timeout': 'idle_timeout',
            'active timeout': 'flow_timeout',
            'sampling rate': 'packet_sample_probability'}
        result = client_object.execute_cmd_get_schema(
            command, ipfix_table_attributes_map, cls.IPFIX_TABLE_TYPE,
            ipfix_table_schema.IPFIXTableSchema, key_val_sep='=').table[0]
        return cls._format_ipfix_config(result)

    @classmethod
    def _format_ipfix_config(cls, schema_obj):
        """
        Converts the given schema object to a format consumable by the test.
        1) Stripts the time units from timeout values.
        2) Splits collector ip:port to separate keys as they were used while
           configuration.

        @type schema_obj: ipfix_table_schema.IPFIXTableSchema.
        @param schema_obj: IPFIXTableSchema object.
        @rtype: ipfix_table_schema.IPFIXTableSchema.
        @return: Returns the formatted IPFIXTableSchema object.
        """
        # Strip the time units and just return integers.
        schema_obj.idle_timeout = schema_obj.idle_timeout.rstrip(" seconds")
        schema_obj.flow_timeout = schema_obj.flow_timeout.rstrip(" seconds")
        # Split ip:port to different keys to be consistent with input.
        schema_obj.ip_address, schema_obj.port = \
            schema_obj.collector.rsplit(":", 1)
        # Delete the unwanted key.
        del schema_obj.collector
        return schema_obj
