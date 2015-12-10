import vmware.common.base_client as base_client
import vmware.common.connections.soap_connection as soap_connection
import vmware.common.global_config as global_config
import vmware.example_project.inventory as inventory

pylogger = global_config.pylogger


# *APIClient is used for all implementation that
# uses product's API/SDK
class InventoryAPIClient(inventory.ExampleInventory,
                         base_client.BaseAPIClient):

    # Implement get_connection in all inventory client class.
    # Otherwise, NotImplemened exception will be thrown from
    # base_client
    def get_connection(self):
        # the connection object can be soap/https
        # depending on the product implementation
        return soap_connection.SOAPConnection(
            self.ip, self.username, self.password)
