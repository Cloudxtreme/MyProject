import vmware.base.profile as profile


class FabricProfile(profile.Profile):

    def __init__(self, parent=None):
        super(FabricProfile, self).__init__()
        self.parent = parent
        self.id_ = None

    def get_id_(self):
        return self.id_

    def get_fabric_profile_id(self):
        return self.id_
