import vmware.base.profile as profile


class UplinkProfile(profile.Profile):

    def __init__(self, parent=None, id_=None):
        self.parent = parent
        self.id_ = id_

    def get_uplink_profile_id(self):
        return self.id_
