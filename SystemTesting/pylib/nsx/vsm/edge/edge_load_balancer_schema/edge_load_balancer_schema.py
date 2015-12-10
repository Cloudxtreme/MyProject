import base_schema
from logging_schema import LoggingSchema
from edge_load_balancer_gslbserviceconfig_schema import LoadBalancergslbServiceConfigSchema
from edge_load_balancer_application_rule_schema import LoadBalancerApplicationRuleSchema
from edge_load_balancer_virtual_server_schema import LoadBalancerVirtualServerSchema
from edge_load_balancer_application_profile_schema import LoadBalancerApplicationProfileSchema
from edge_load_balancer_pool_schema import LoadBalancerPoolSchema
from edge_load_balancer_monitor_schema import LoadBalancerMonitorSchema
from edge_load_balancer_global_service_instance_schema import LoadBalancerGlobalServiceInstanceSchema


class LoadBalancerSchema(base_schema.BaseSchema):
    _schema_name = "loadBalancer"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.enableServiceInsertion = None
        self.accelerationEnabled = None
        self.logging = LoggingSchema()
        self.gslbServiceConfig = [LoadBalancergslbServiceConfigSchema()]
        self.applicationRule = [LoadBalancerApplicationRuleSchema()]
        self.virtualServer = [LoadBalancerVirtualServerSchema()]
        self.applicationProfile = [LoadBalancerApplicationProfileSchema()]
        self.pool = LoadBalancerPoolSchema()
        self.monitor = [LoadBalancerMonitorSchema()]
        self.globalServiceInstance = LoadBalancerGlobalServiceInstanceSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
