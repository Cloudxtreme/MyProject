import vmware.nsx.manager.manager_client as manager_client
import vmware.nsx.manager.spoof_guard_profile.spoof_guard_profile\
    as spoof_guard_profile


class SpoofGuardProfileAPIClient(spoof_guard_profile.SpoofGuardProfile,
                                 manager_client.NSXManagerAPIClient):
    pass
