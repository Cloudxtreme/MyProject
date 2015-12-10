"""Interface class to implement authentication server related operations."""


class AuthServerInterface(object):

    @classmethod
    def configure_service_state(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def add_user(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def backup_config_file(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def restore_config_file(cls, client_object, **kwargs):
        raise NotImplementedError
