class MessagingServerInterface(object):

    @classmethod
    def get_users_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_vhosts_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_user_permissions_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_permissions_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_queues_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_exchanges_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_bindings_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_connections_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_channels_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_consumers_list(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def start(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def stop(cls, client_object, **kwargs):
        raise NotImplementedError