import vmware.common.compute_utilities as compute_utilities
import vmware.common.constants as constants
import vmware.interfaces.power_interface as power_interface



class LinuxPowerImpl(power_interface.PowerInterface):

    @classmethod
    def enter_maintenance_mode(cls, client_object):
        raise NotImplementedError

    @classmethod
    def exit_maintenance_mode(cls, client_object):
        raise NotImplementedError

    @classmethod
    def off(cls, client_object):
        return client_object.connection.request(
            constants.HostAction.POWEROFF)

    @classmethod
    def on(cls, client_object):
        raise NotImplementedError

    @classmethod
    def async_reboot(cls, client_object):
        return client_object.connection.request(
            constants.HostAction.REBOOT)

    @classmethod
    def reboot(cls, client_object):
        return (cls.async_reboot(client_object) and
                cls.wait_for_reboot(client_object))

    @classmethod
    def reset(cls, client_object):
        raise NotImplementedError

    @classmethod
    def shutdown(cls, client_object):
        return client_object.connection.request(
            "%s -h now" % constants.HostAction.SHUTDOWN)

    @classmethod
    def wait_for_reboot(cls, client_object, timeout=None, post_reboot_sleep=None):
        return compute_utilities.wait_for_ip_reachable(
            client_object.connection.ip, timeout=timeout,
            post_reboot_sleep=post_reboot_sleep)

    @classmethod
    def get_power_state(cls, client_object):
        return compute_utilities.wait_for_ip_reachable(
            client_object.connection.ip, timeout=1, post_reboot_sleep=0)
