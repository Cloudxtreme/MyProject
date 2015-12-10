import vmware.base.certificate as certificate
import vmware.nsx.manager.nsxbase as nsxbase


class CSR(nsxbase.NSXBase, certificate.Certificate):

    def get_csr_id(self):
        return self.id_

    def get_id_(self):
        return self.id_