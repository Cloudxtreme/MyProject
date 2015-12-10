import base_schema
import resource_link_schema
import tag_schema

class LoadBalancerGlobalSiteSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerglobalsite"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGlobalSiteSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerGlobalSiteSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [tag_schema.TagSchema()]
        self.management_port = None
        self.id = None
        self.site_server_ips = [str]
        self._create_time = None
        self.management_ip = None
        self.geo_location = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self._last_modified_time = None
        self.revision = None
        self._last_modified_user = None
        self.geo_type = None
        self.name = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)