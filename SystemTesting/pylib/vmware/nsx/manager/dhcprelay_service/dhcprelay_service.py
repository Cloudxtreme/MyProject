import vmware.base.service as service


class DHCPRelayService(service.Service):

    def __init__(self, parent=None):
        super(DHCPRelayService, self).__init__()
        self.parent = parent
        self.id_ = None

    def get_profile_id(self):
        return self.id_
