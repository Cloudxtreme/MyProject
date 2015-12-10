import base_schema
import vmware.common.logger as logger
import tag_schema

class Registration(base_schema.BaseSchema):
    _schema_name = "registration"

    def __init__(self, py_dict=None):
        super(Registration, self).__init__()
        self.display_name = None
        self.address = None
        self.user = None
        self.password = None
        self.cert_thumbprint = None
        self.schema = None
        self.id = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

if __name__ == '__main__':
    vsm_register = Registration()
    vsm_register.set_data('{"display_name":"VSM-1","address":"10.110.28.190","user": "root"}', 'json')
    print vsm_register.display_name
    print vsm_register.get_data('json')
