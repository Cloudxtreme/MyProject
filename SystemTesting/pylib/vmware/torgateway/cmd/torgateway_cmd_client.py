#!/usr/bin/env python
import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.torgateway.torgateway as torgateway

pylogger = global_config.pylogger


class TORGatewayCMDClient(torgateway.TORGateway, base_client.BaseCMDClient):

    def get_connection(self):
        return ssh_connection.SSHConnection(
            self.ip, self.username, self.password)
