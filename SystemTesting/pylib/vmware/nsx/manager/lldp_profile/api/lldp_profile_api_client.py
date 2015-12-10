import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class LldpProfileAPIClient(profile.Profile,
                           manager_client.NSXManagerAPIClient):
    pass
