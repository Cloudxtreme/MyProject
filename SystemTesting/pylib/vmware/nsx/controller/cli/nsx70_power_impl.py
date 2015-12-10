import vmware.common.compute_utilities as compute_utilities
import vmware.common.global_config as global_config
import vmware.interfaces.power_interface as power_interface

pylogger = global_config.pylogger


class NSX70PowerImpl(power_interface.PowerInterface):
    @classmethod
    def configure_power_state(cls, client_obj, state=None):
        if state == 'shutdown' or state == 'reboot':
            # Execute the command
            client_obj.connection.request(state, ['bytes*', ':'])
            client_obj.connection.request('yes', ['bytes*', '>'])
        else:
            raise ValueError("Received unknown state [%s] for power"
                             " configuration" % state)
        return True

    @classmethod
    def reboot(cls, client_object):
        cls.configure_power_state(client_object, state='reboot')
        return compute_utilities.wait_for_ip_reachable(
            client_object.connection.ip)
