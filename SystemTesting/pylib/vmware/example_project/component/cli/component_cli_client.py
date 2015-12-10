#!/usr/bin/env python

import vmware.base.example as example
import vmware.common.global_config as global_config
import vmware.example_project.component.component as component
import vmware.example_project.cli.inventory_cli_client as inventory_cli_client

pylogger = global_config.pylogger


# *CLIClient is used for all implementation that
# uses product's CLI
class ComponentCLIClient(component.ExampleComponent,
                         inventory_cli_client.InventoryCLIClient):
    def __init__(self, parent=None, id_=None):
        super(ComponentCLIClient, self).__init__(parent=parent)
        self.id_ = id_
