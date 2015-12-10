import vmware.base.profile as profile


class ClusterProfile(profile.Profile):

    def __init__(self, parent=None, id_=None):
        super(ClusterProfile, self).__init__(parent=parent, id_=id_)

    def get_id_(self):
        return self.id_

    def get_cluster_profile_id(self):
        return self.id_
