import vmware.base.certificate as certificate
import vmware.nsx.manager.manager_client as manager_client


class CSRCLIClient(certificate.Certificate, manager_client.NSXManagerCLIClient):

    def __init__(self, parent=None, id_=None):
        super(CSRCLIClient, self).__init__(parent=parent)
        self.id_ = id_
