import vmware.common.base_facade as base_facade
import vmware.base.base as base
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class Messaging(base.Base):

    def __init__(self, parent=None):
        super(Messaging, self).__init__()
        self.parent = parent

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_users_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_vhosts_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_user_permissions_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_permissions_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_queues_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_exchanges_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_bindings_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_connections_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_channels_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def get_consumers_list(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def stop(self, **kwargs):
        pass

    @auto_resolve(labels.MESSAGING_SERVER)
    def start(self, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def ping_client(self, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def heartbeat_status(self, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_distributed_clients(self, **kwargs):
        pass
