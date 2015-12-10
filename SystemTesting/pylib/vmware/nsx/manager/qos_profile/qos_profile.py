import vmware.base.profile as profile
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config


auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class QosProfile(profile.Profile):
    """
    Switching profile class for NSX Manager QoS.
    """
    def __init__(self, parent=None):
        super(QosProfile, self).__init__()
        self.parent = parent
