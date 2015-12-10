import vmware.nsx.manager.routing.bgp.bgp as bgp
import vmware.nsx.manager.manager_client as manager_client


class BGPCLIClient(bgp.BGP, manager_client.NSXManagerCLIClient):
    pass
