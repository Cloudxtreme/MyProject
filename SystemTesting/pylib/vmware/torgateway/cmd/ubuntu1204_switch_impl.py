import vmware.common.global_config as global_config
import vmware.interfaces.switch_interface as switch_interface
import vmware.linux.ovs.cli.default_crud_impl as default_crud_impl

pylogger = global_config.configure_logger()
DefaultCRUDImpl = default_crud_impl.DefaultCRUDImpl


class Ubuntu1204SwitchImpl(switch_interface.SwitchInterface):
    """Switch management class for Ubuntu."""
    BIND_CMD = "vtep-ctl "

    @classmethod
    def bind_pnic(cls, client_object, name=None, switch_name=None):

        if name is None:
            raise ValueError('Adapter name cannot be None')

        if switch_name is None:
            raise ValueError('Switch name cannot be None')

        ip = None
        parsed_data = DefaultCRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['dev'] == name:
                ip = record['ip']

        if ip is None:
            raise ValueError('Adapter has no IP')

        bind_cmd = cls.BIND_CMD + " set Physical_Switch "
        bind_cmd = bind_cmd + str(switch_name) + " tunnel_ips=" + str(ip)
        client_object.connection.request(bind_cmd)
