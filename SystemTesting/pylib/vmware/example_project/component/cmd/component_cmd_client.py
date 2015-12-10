#!/usr/bin/env python

import vmware.base.example as example
import vmware.common.global_config as global_config
import vmware.example_project.component.component as component
import vmware.example_project.cmd.inventory_cmd_client as inventory_cmd_client

pylogger = global_config.pylogger


# *CMDClient is used for all implementation that
# uses product's shell command
class ComponentCMDClient(component.ExampleComponent,
                         inventory_cmd_client.InventoryCMDClient):
    def __init__(self, parent=None, id_=None):
        super(ComponentCMDClient, self).__init__(parent=parent)
        self.id_ = id_
