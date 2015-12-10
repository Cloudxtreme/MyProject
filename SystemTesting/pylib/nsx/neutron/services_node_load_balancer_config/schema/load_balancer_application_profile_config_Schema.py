import base_schema
import resource_link_schema
import tag_schema
import load_balancer_server_ssl_schema
import load_balancer_http_redirect_schema
import load_balancer_client_ssl_schema
import load_balancer_persistence_schema

class LoadBalancerApplicationProfileConfigSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerapplicationprofileconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerApplicationProfileConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerApplicationProfileConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.insert_x_forwarded_for = None
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [tag_schema.TagSchema()]
        self.server_ssl = load_balancer_server_ssl_schema.LoadBalancerServerSslSchema()
        self.http_redirect = \
            load_balancer_http_redirect_schema.LoadBalancerHttpRedirectSchema()
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.template = None
        self.client_ssl = load_balancer_client_ssl_schema.LoadBalancerClientSslSchema()
        self.ssl_passthrough = None
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.persistence = \
            load_balancer_persistence_schema.LoadBalancerPersistenceSchema()
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)