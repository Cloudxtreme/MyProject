import vmware.common.base_client as base_client
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.common.global_config as global_config
import vmware.example_project.inventory as inventory

pylogger = global_config.pylogger


# *CLIClient is used for all implementation that
# uses product's CLI
class InventoryCLIClient(inventory.ExampleInventory,
                         base_client.BaseCLIClient):

    def get_connection(self):
        # the connection object can be ssh or pexpect
        # depending on the product's cli implementation
        return ssh_connection.SSHConnection(
            self.ip, self.username, self.password)
