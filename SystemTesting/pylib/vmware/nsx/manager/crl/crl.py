import vmware.base.certificate as certificate


class CRL(certificate.Certificate):

    def __init__(self, parent=None):
        super(CRL, self).__init__()
        self.parent = parent

    def get_id_(self):
        return self.id_