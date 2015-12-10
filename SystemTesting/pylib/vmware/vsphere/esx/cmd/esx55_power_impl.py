import time

import vmware.common.compute_utilities as compute_utilities
import vmware.common.constants as constants
import vmware.interfaces.power_interface as power_interface


class ESX55PowerImpl(power_interface.PowerInterface):

    @classmethod
    def on(cls, client_object):
        raise NotImplementedError

    @classmethod
    def off(cls, client_object):
        return client_object.cmd_connection_object.request(
            constants.HostAction.POWEROFF)

    @classmethod
    def enter_maintenance_mode(cls, client_object):
        raise NotImplementedError

    @classmethod
    def exit_maintenance_mode(cls, client_object):
        raise NotImplementedError

    @classmethod
    def reset(cls, client_object):
        raise NotImplementedError

    @classmethod
    def reboot(cls, client_object):
        return client_object.cmd_connection_object.request(
            constants.HostAction.REBOOT)

    @classmethod
    def shutdown(cls, client_object):
        raise NotImplementedError


    @classmethod
    def wait_for_reboot(cls, client_object, timeout=None, post_reboot_sleep=None):
        return compute_utilities.wait_for_ip_reachable(
            client_object.cmd_connection_object.ip, timeout=timoeut,
            post_reboot_sleep=post_reboot_sleep)
