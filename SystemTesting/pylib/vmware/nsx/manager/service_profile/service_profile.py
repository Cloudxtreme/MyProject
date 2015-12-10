import vmware.base.profile as profile


class ServiceProfile(profile.Profile):

    def __init__(self, parent=None):
        super(ServiceProfile, self).__init__()
        self.parent = parent
        self.id_ = None

    def get_profile_id(self):
        return self.id_