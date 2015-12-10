import vmware.auth_server.auth_server as authentication_server
import vmware.common.base_client as base_client
import vmware.common.connections.expect_connection as expect_connection


class AuthServerCLIClient(authentication_server.AuthServer,
                          base_client.BaseCLIClient):

    def get_connection(self):
        return expect_connection.ExpectConnection(
            self.ip, self.username, self.password)