import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class DefaultCrudImpl(crud_interface.CRUDInterface):
    # XXX(salmanm):
    #   - The UUID might need to be set and retrieved from the OVS's root
    #     table when/if the product expects the UUID to be set in the datapath.
    #   - We should make sure that when we set this UUID ourselves, then we set
    #     it only once, ideally when the KVM is being cloned.
    @classmethod
    def get_system_id(cls, client_object):
        command = 'dmidecode -s system-uuid'
        pylogger.info('Command to get system uuid for host: %s' % command)
        return client_object.connection.request(
            command).response_data.strip().lower()