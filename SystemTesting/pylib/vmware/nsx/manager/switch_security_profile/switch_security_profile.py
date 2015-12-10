import vmware.base.profile as profile
import vmware.common.versions as versions


class SwitchSecurityProfile(profile.Profile):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.BUMBLEBEE

    def __init__(self, parent=None, id_=None):
        super(SwitchSecurityProfile, self).__init__(parent=parent, id_=id_)
