"""Interface class to implement power operations associated with a client"""


class PowerInterface(object):

    @classmethod
    def on(cls, client_object, **kwargs):
        """Interface to power-on a client"""
        raise NotImplementedError

    @classmethod
    def off(cls, client_object, **kwargs):
        """Interface to power-off a client"""
        raise NotImplementedError

    @classmethod
    def enter_maintenance_mode(cls, client_object, **kwargs):
        """Interface to enter maintenance mode for a client"""
        raise NotImplementedError

    @classmethod
    def exit_maintenance_mode(cls, client_object, **kwargs):
        """Interface to exit maintenance mode for a client"""
        raise NotImplementedError

    @classmethod
    def reboot(cls, client_object, **kwargs):
        """Interface to reboot a client"""
        raise NotImplementedError

    @classmethod
    def async_reboot(cls, client_object, **kwargs):
        """Interface to asynchronously reboot a client"""
        raise NotImplementedError

    @classmethod
    def wait_for_reboot(cls, client_object, timeout=None,
                        post_reboot_sleep=None, **kwargs):
        """Interface to wait for reboot for a client"""
        raise NotImplementedError

    @classmethod
    def reset(cls, client_object, **kwargs):
        """Interface to reset a client"""
        raise NotImplementedError

    @classmethod
    def shutdown(cls, client_object, **kwargs):
        """Interface to shutdown a client"""
        raise NotImplementedError

    @classmethod
    def get_power_state(cls, client_object, **kwargs):
        """Interface to get client power state"""
        raise NotImplementedError

    @classmethod
    def configure_power_state(cls, client_object, state=None, **kwargs):
        """Interface to configure client power state"""
        raise NotImplementedError
