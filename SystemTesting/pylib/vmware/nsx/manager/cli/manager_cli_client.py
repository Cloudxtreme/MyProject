#!/usr/bin/env python

import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.common.connections.expect_connection as expect_connection
import vmware.nsx.manager.manager as manager

pylogger = global_config.pylogger


class ManagerCLIClient(manager.Manager, base_client.BaseCLIClient):

    def get_connection(self):
        return expect_connection.ExpectConnection(
            ip=self.ip, username=self.username, password=self.password,
            root_password=self.root_password)
