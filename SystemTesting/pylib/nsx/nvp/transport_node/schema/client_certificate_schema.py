import base_schema
import tag_schema

class ClientCertificate(base_schema.BaseSchema):
    _schema_name = "clientCertificate"

    def __init__(self, py_dict=None):
        super(ClientCertificate, self).__init__()
        self.pem_encoded = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

        self._pem_encoded_meta = {'isReq':True,'type':'string'}

if __name__=='__main__':
    pass
