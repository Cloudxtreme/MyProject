import vmware.log_server.log_server as logging_server
import vmware.common.base_client as base_client
import vmware.vapi.lib.connect as connect


class LogServerAPIClient(logging_server.LogServer,
                         base_client.BaseAPIClient):

    def get_connection(self):
        return connect.get_connector("vmware", "protobuf",
                                     url="vmware://" + self.ip + ":9240")
