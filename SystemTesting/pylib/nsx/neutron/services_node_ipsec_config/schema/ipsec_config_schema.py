import base_schema
import resource_link_schema
import tag_schema
import site_ipsec_config_schema
import logging_config_schema
import global_ipsec_config_schema

class IpSecConfigSchema(base_schema.BaseSchema):
    _schema_name = "ipsecconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create IpSecConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(IpSecConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [tag_schema.TagSchema()]
        self.enabled = None
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.site_configs = [site_ipsec_config_schema.SiteIpSecConfigSchema()]
        self.template = None
        self.logging = logging_config_schema.LoggingConfigSchema()
        self._last_modified_time = None
        self.global_configs = [global_ipsec_config_schema.GlobalIpSecConfigSchema()]
        self._last_modified_user = None
        self.id = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)