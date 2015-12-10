import base_schema
import vmware.common.logger as logger
import tag_schema

class NVPRegistration(base_schema.BaseSchema):
    _schema_name = "nvp_registration"

    def __init__(self, py_dict=None):
        super(NVPRegistration, self).__init__()
        self.id = None
        self.user = None
        self.password = None
        self.address = None
        self.schema = None
        self.cert_thumbprint = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

if __name__ == '__main__':
    nvp_register = NVPRegistration()
    nvp_register.set_data('{"username":"admin","password":"admin","ipaddress":"10.110.28.190"}', 'json')
    print nvp_register.username
    print nvp_register.get_data('json')
