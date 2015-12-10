import base_schema
import resource_link_schema
import load_balancer_global_ip_schema
import load_balancer_application_rule_schema
import load_balancer_global_service_config_schema
import load_balancer_monitor_schema
import load_balancer_global_site_schema
import virtual_servers_schema
import logging_config_schema
import load_balancer_application_profile_config_Schema
import tag_schema
import load_balancer_pool_config_schema

class LoadBalancerConfigSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.global_ips = [load_balancer_global_ip_schema.LoadBalancerGlobalIpSchema()]
        self.application_rules = \
            [load_balancer_application_rule_schema.LoadBalancerApplicationRuleSchema()]
        self.display_name = None
        self.description = None
        self._create_user = None
        self.monitors = \
            [load_balancer_monitor_schema.LoadBalancerMonitorSchema()]
        self.global_sites = \
            [load_balancer_global_site_schema.LoadBalancerGlobalSiteSchema()]
        self.id = None
        self._create_time = None
        self.schema = None
        self.virtual_servers = [virtual_servers_schema.VirtualServerConfigSchema()]
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.logging = logging_config_schema.LoggingConfigSchema()
        self._last_modified_time = None
        self.application_profiles = \
        [load_balancer_application_profile_config_Schema.LoadBalancerApplicationProfileConfigSchema()]
        self._last_modified_user = None
        self.acceleration_enabled = None
        self.tags = [tag_schema.TagSchema()]
        self.revision = None
        self.pools = [load_balancer_pool_config_schema.LoadBalancerPoolConfigSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)