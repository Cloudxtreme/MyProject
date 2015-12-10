import base_schema
from certificate_schema import CertificateSchema

class CertificatesSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "x509Certificates"
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(CertificatesSchema, self).__init__()
        self.set_data_type('xml')

        self.list = [CertificateSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
