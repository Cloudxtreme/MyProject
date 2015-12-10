import base_schema
import resource_link_schema

class SiteIpSecConfigSchema(base_schema.BaseSchema):
    _schema_name = "siteipsecconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create SiteIpSecConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(SiteIpSecConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.psk = None
        self.peer_subnets = [str]
        self.description = None
        self.certificate = None
        self.local_ip = None
        self.dh_group = None
        self.name = None
        self.enable_pfs = None
        self.enabled = None
        self.mtu = None
        self.encryption_algorithm = None
        self.schema = None
        self.local_id = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.extension = None
        self.authentication_mode = None
        self.peer_id = None
        self.revision = None
        self.peer_ip = None
        self.local_subnets = [str]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)