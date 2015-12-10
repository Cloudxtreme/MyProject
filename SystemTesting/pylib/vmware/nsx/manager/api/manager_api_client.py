import vmware.common.global_config as global_config
import vmware.nsx.manager.manager as manager
import vmware.common.base_client as base_client
import vmware.nsx_api.base.https_connection as https_connection

pylogger = global_config.pylogger


class ManagerAPIClient(manager.Manager, base_client.BaseAPIClient):

    def get_connection(self):
        return https_connection.HTTPSConnection(
            self.ip, self.username, self.password)
