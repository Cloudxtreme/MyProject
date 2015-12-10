#!/usr/bin/env python

# sort imports in alphabetical order
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config

import vmware.example_project.inventory as inventory
import vmware.example_project.cli.inventory_cli_client as inventory_cli_client
import vmware.example_project.cmd.inventory_cmd_client as inventory_cmd_client
import vmware.example_project.api.inventory_api_client as inventory_api_client

pylogger = global_config.pylogger


# Create client facade class for every inventory
# item in a product/project. This class inherits
# from the base abstract class. For example,
# ESXClientFacade inherits from hypervisor class.
class InventoryFacade(inventory.ExampleInventory, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, ip=None, username=None, password=None, parent=None):
        self.ip = ip
        self.username = username
        self.password = password
        self.parent = parent

        # Instantiate client objects corresponding to execution types
        # supported.
        # At least one client object should be instantiated.
        # The implementation may or may not have/support all different
        # execution type. So, instantiate clients only that are required
        api_client = inventory_api_client.InventoryAPIClient(
            ip=self.ip, username=self.username, password=self.password)
        cli_client = inventory_cli_client.InventoryCLIClient(
            ip=self.ip, username=self.username, password=self.password)
        cmd_client = inventory_cmd_client.InventoryCMDClient(
            ip=self.ip, username=self.username, password=self.password)
        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.CMD: cmd_client}


if __name__ == "__main__":
    import vmware.example_project.inventory_facade as inventory_facade
    inventory_facade_obj = inventory_facade.InventoryFacade(
        ip="10.144.138.189", username="root", password="ca$hc0w")

    pylogger.info("### Test inventory facade ###")
    inventory_facade_obj.initialize()
    try:
        inventory_facade_obj.method01()
    except Exception, e:
        pylogger.info('Error returned by method01: %s' % e.status_code)
    try:
        inventory_facade_obj.method02()
    except Exception, e:
        pylogger.info('Error returned by method02: %s' % e.status_code)
    try:
        inventory_facade_obj.method02(required_param='a')
    except Exception, e:
        pylogger.info('Error returned by method02: %s' % e.status_code)
    inventory_facade_obj.method02(required_param='a', int_param=1)

    pylogger.info("### Test inventory cli client ###")
    inventory_cli_client = inventory_cli_client.InventoryCLIClient(
        ip="10.144.138.189", username="root", password="ca$hc0w")
    try:
        inventory_facade_obj.method01()
    except Exception, e:
        pylogger.info('Error returned by method01: %s' % e.status_code)
    try:
        inventory_facade_obj.method02()
    except Exception, e:
        pylogger.info('Error returned by method02: %s' % e.status_code)
    try:
        inventory_facade_obj.method02(required_param='a')
    except Exception, e:
        pylogger.info('Error returned by method02: %s' % e.status_code)
    inventory_facade_obj.method02(required_param='a', int_param=1)
