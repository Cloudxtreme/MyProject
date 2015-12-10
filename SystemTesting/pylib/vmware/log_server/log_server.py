import vmware.base.server as server
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class LogServer(server.Server):

    @auto_resolve(labels.LOG_SERVER)
    def verify_audit_logs(self, execution_type=None, **kwargs):
        """Configures a Logging Server with desired parameters."""
        pass