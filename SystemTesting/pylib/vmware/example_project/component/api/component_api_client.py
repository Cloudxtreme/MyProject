#!/usr/bin/env python

import vmware.base.example as example
import vmware.common.global_config as global_config
import vmware.example_project.component.component as component
import vmware.example_project.api.inventory_api_client as inventory_api_client

pylogger = global_config.pylogger


# *APIClient is used for all implementation that
# uses product's API/SDK
class ComponentAPIClient(component.ExampleComponent,
                         inventory_api_client.InventoryAPIClient):
    def __init__(self, parent=None, id_=None):
        super(ComponentAPIClient, self).__init__(parent=parent)
        self.id_ = id_
