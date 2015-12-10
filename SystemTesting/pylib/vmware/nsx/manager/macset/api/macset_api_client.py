import vmware.nsx.manager.macset.macset as macset
import vmware.nsx.manager.manager_client as manager_client


class MACSetAPIClient(macset.MACSet,
                      manager_client.NSXManagerAPIClient):
    pass
