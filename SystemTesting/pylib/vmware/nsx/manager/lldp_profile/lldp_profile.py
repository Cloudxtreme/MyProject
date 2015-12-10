import vmware.base.profile as profile
import vmware.common.versions as versions


class LldpProfile(profile.Profile):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.BUMBLEBEE

    def __init__(self, parent=None, id_=None):
        super(LldpProfile, self).__init__(parent=parent, id_=id_)
        self.parent = parent
        self.id_ = id_

    def get_lldp_profile_id(self):
        return self.id_
