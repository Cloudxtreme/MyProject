import vmware.base.certificate as certificate
import vmware.nsx.manager.manager_client as manager_client


class CSRAPIClient(certificate.Certificate, manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(CSRAPIClient, self).__init__(parent=parent)
        self.id_ = id_
