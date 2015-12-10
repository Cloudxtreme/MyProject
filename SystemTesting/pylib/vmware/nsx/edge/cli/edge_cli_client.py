import vmware.common.base_client as base_client
import vmware.nsx.edge.edge as edge
import vmware.common.connections.expect_connection as expect_connection


class EdgeCLIClient(edge.Edge,
                    base_client.BaseCLIClient):

    def get_connection(self):
        return expect_connection.ExpectConnection(
            ip=self.ip, username=self.username, password=self.password,
            terminal_prompts=['.#', '.>'])
