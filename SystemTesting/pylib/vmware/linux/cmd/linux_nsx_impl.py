import vmware.common.global_config as global_config
import vmware.interfaces.nsx_interface as nsx_interface
import vmware.schema.controller.nsx_controller_schema as nsx_controller_schema

pylogger = global_config.pylogger


class LinuxNSXImpl(nsx_interface.NSXInterface):

    CONFIG_BY_VSM = "/etc/vmware/nsx/config-by-vsm.xml"
    NSX_CONTROLLER_TYPE = "raw/nsxController"

    @classmethod
    def get_controller(cls, client_object, **kwargs):
        command = "cat %s " % cls.CONFIG_BY_VSM
        pylogger.info("Getting controller list by %r" % command)
        controller_table_attributes_map = {
            'controller': 'controller_ip',
            'port': 'port',
            'sslenabled': 'ssl_enabled',
            'count': 'count'
        }
        return client_object.execute_cmd_get_schema(
            command, controller_table_attributes_map, cls.NSX_CONTROLLER_TYPE,
            nsx_controller_schema.NsxControllerTableSchema)
