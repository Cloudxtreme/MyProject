import vmware.common.global_config as global_config
import vmware.nsx.manager.manager as manager
import vmware.common.base_client as base_client
import vmware.nsx_api.base.http_connection as http_connection

pylogger = global_config.pylogger


class ManagerUIClient(manager.Manager, base_client.BaseUIClient):

    def get_connection(self):
        return http_connection.HTTPConnection(
            self.ip, self.username, self.password)
