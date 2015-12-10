#!/usr/bin/env python

import vmware.nsx.controller.controller as controller
import vmware.common.base_client as base_client
import vmware.common.connections.expect_connection as expect_connection
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ControllerCLIClient(controller.Controller, base_client.BaseCLIClient):
    def get_connection(self):
        return expect_connection.ExpectConnection(
            ip=self.ip, username=self.username, password=self.password)
