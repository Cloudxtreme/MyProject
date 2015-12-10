import vmware.base.profile as profile


class DHCPRelayProfile(profile.Profile):

    def __init__(self, parent=None):
        super(DHCPRelayProfile, self).__init__()
        self.parent = parent
        self.id_ = None

    def get_profile_id(self):
        return self.id_