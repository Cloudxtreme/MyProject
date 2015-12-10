import vmware.base.server as server
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class AuthServer(server.Server):

    def get_impl_version(self, execution_type=None, interface=None):
        return 'TACACS'

    @auto_resolve(labels.AUTH_SERVER)
    def configure_service_state(self, execution_type=None, **kwargs):
        """Stops/Starts the AUTH Server"""
        pass

    @auto_resolve(labels.AUTH_SERVER)
    def add_user(self, execution_type=None, **kwargs):
        """adds user to the AUTH Server"""
        pass

    @auto_resolve(labels.AUTH_SERVER)
    def backup_config_file(self, execution_type=None, **kwargs):
        """make a copy of AUTH Server config file"""
        pass

    @auto_resolve(labels.AUTH_SERVER)
    def restore_config_file(self, execution_type=None, **kwargs):
        """restore AUTH Server config file"""
        pass
