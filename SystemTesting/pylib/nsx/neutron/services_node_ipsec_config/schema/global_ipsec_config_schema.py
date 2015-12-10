import base_schema
import resource_link_schema

class GlobalIpSecConfigSchema(base_schema.BaseSchema):
    _schema_name = "globalipsecconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create GlobalIpSecConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(GlobalIpSecConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.psk = None
        self.extension = None
        self.crl_certificates = [str]
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.service_certificate = None
        self.schema = None
        self.ca_certificates = [str]
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)