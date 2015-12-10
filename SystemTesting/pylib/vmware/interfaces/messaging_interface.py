"""Interface class to implement messaging related operations."""


class MessagingInterface(object):

    @classmethod
    def ping_client(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def read_master_broker_ip(cls, client_object, **kwargs):
        """Interface to to read master broker ip of a host """
        raise NotImplementedError

    @classmethod
    def get_broker_ip(cls, client_object, num=0, **kwargs):
        """Read the mpaconfig and get the broker ip """
        raise NotImplementedError

    @classmethod
    def get_broker_port(cls, client_object, num=0, **kwargs):
        """Read the mpaconfig and get the broker port """
        raise NotImplementedError

    @classmethod
    def get_broker_thumbprint(cls, client_object, num=0, **kwargs):
        """Read the mpaconfig and get the broker thumbprint """
        raise NotImplementedError

    @classmethod
    def get_client_token(cls, client_object, **kwargs):
        """Read the mpaconfig and get the account name/client-token """
        raise NotImplementedError

    @classmethod
    def read_broker_thumbprint(cls, client_object, **kwargs):
        """ Return the broker thumbprint as a dictionary """
        raise NotImplementedError

    @classmethod
    def read_client_token(cls, client_object, read_client_token=None,
                          **kwargs):
        """ Return the client token/Account name as a dictionary """
        raise NotImplementedError

    @classmethod
    def connect_sample_client(cls, client_object, host_ip=None, name=None):
        raise NotImplementedError

    @classmethod
    def vertical_registration(cls, client_object, host_ip=None,
                              application_type=None, application_id=None,
                              client_type=None, registration_options=None,
                              vertical_registration=None):
        raise NotImplementedError

    @classmethod
    def vertical_close_connection(cls, client_object, host_ip=None,
                                  cookieid=None):
        raise NotImplementedError

    @classmethod
    def vertical_send_msg(cls, client_object, host_ip=None, count=1,
                          cookie_id=None, msg_type=None, test_params=None):
        raise NotImplementedError

    # TODO smyneni: Deprecate methods below once kvm is refactored
    @classmethod
    def vertical_send_generic_msg(cls, client_object,
                                  host_ip=None, amqp_payload=None, count=1,
                                  cookieid=None):
        raise NotImplementedError

    # TODO smyneni: Deprecate methods below once kvm is refactored
    @classmethod
    def vertical_send_rpc_msg(cls, client_object,
                              host_ip=None, amqp_payload=None, count=1,
                              cookieid=None):
        raise NotImplementedError

    # TODO smyneni: Deprecate methods below once kvm is refactored
    @classmethod
    def vertical_send_publish_msg(cls, client_object,
                                  host_ip=None, amqp_payload=None, count=1,
                                  cookieid=None):
        raise NotImplementedError
