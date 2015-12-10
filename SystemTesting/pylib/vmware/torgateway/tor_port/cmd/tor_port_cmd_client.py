#!/usr/bin/env python

import vmware.torgateway.tor_port.tor_port as torport
import vmware.common.base_client as base_client
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class TORPortCMDClient(torport.TORPort, base_client.BaseCMDClient):

    def __init__(self, parent=None, name=None):
        super(TORPortCMDClient, self).__init__(parent=parent)
        self.name = name
        pylogger.debug('Name of port: %s' % self.name)

    def get_connection(self):
        return ssh_connection.SSHConnection(
            ip=self.ip, username=self.username, password=self.password)
