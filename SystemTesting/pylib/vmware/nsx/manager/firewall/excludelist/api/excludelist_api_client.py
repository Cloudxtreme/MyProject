import vmware.nsx.manager.firewall.excludelist.excludelist as excludelist  # noqa
import vmware.nsx.manager.manager_client as manager_client


class ExcludeListAPIClient(excludelist.ExcludeList,
                           manager_client.NSXManagerAPIClient):
    pass
