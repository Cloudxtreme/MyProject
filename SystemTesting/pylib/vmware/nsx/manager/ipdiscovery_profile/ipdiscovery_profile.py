import vmware.base.profile as profile
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config


auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class IPDiscoveryProfile(profile.Profile):
    """
    IP Discovery Switching profile class for NSX Manager.
    """
    def __init__(self, parent=None, id_=None):
        super(IPDiscoveryProfile, self).__init__()
        self.parent = parent
        self.id_ = id_
