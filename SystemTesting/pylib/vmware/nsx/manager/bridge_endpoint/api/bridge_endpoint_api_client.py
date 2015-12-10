import vmware.nsx.manager.bridge_endpoint.bridge_endpoint as bridge_endpoint
import vmware.nsx.manager.manager_client as manager_client


class BridgeEndpointAPIClient(bridge_endpoint.BridgeEndpoint,
                              manager_client.NSXManagerAPIClient):
    pass
