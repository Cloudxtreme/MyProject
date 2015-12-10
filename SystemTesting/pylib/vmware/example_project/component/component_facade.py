#!/usr/bin/env python

import vmware.base.example as example
import vmware.common.constants as constants
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.example_project.component.component as component
import vmware.example_project.component.cli.component_cli_client as \
    component_cli_client
import vmware.example_project.component.cmd.component_cmd_client as \
    component_cmd_client
import vmware.example_project.component.api.component_api_client as \
    component_api_client
import vmware.example_project.inventory_facade as inventory_facade

pylogger = global_config.pylogger


# Create client facade class for every component
# to be managed in a product/project. This class inherits
# from the base abstract class and inventory facade class. For example,
# VDSClientFacade inherits from switch class and VCFacade
class ComponentFacade(component.ExampleComponent,
                      inventory_facade.InventoryFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, parent=None, id_=None):
        super(ComponentFacade, self).__init__(parent=parent)
        # id is built-in keyword in Python, so using id_
        self.id_ = id_

        # instantiate client objects
        api_client = component_api_client.ComponentAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = component_cli_client.ComponentCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))
        cmd_client = component_cmd_client.ComponentCMDClient(
            parent=parent.get_client(constants.ExecutionType.CMD))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.CMD: cli_client}

if __name__ == "__main__":
    import vmware.example_project.inventory_facade as inventory_facade
    import vmware.example_project.component.component_facade \
        as component_facade
    inventory_facade_obj = inventory_facade.InventoryFacade(
        ip="10.144.138.189", username="root", password="ca$hc0w")
    inventory_facade_obj.initialize()
    component_facade_obj = component_facade.ComponentFacade(
        parent=inventory_facade_obj)
    component_facade_obj.method01()
    pylogger.info("Calling method01 on component facade object worked")
    component_facade_obj_02 = component_facade.ComponentFacade(
        parent=inventory_facade_obj)
    component_facade_obj.method02(component=component_facade_obj)
    pylogger.info("Calling method02 on component facade object worked")
