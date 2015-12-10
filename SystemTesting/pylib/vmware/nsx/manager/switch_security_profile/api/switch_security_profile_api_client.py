import vmware.nsx.manager.manager_client as manager_client
import vmware.nsx.manager.switch_security_profile.switch_security_profile\
    as switch_security_profile


class SwitchSecurityProfileAPIClient(switch_security_profile.
                                     SwitchSecurityProfile,
                                     manager_client.NSXManagerAPIClient):
    pass
