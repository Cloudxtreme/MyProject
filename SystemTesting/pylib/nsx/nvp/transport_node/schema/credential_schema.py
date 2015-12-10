import base_schema
import tag_schema
import client_certificate_schema

class Credential(base_schema.BaseSchema):
    _schema_name = "credential"

    def __init__(self, py_dict=None):
        super(Credential, self).__init__()
        self.type = None
        self.mgmt_address = None
        self.client_certificate = client_certificate_schema.ClientCertificate()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

        self._type_meta = {'isReq':'True','type':'string'}
        self._client_certificate_meta = {'isReq':'True','type':'object'}

if __name__=='__main__':
    pass
