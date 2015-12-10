import base_schema
import resource_link_schema
import tag_schema

class LoadBalancerMonitorSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancermonitor"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerMonitorSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerMonitorSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.id = None
        self.monitor_id = None
        self.display_name = None
        self.send = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.expected = None
        self.type = None
        self.method = None
        self.schema = None
        self.description = None
        self.tags = [tag_schema.TagSchema()]
        self._create_time = None
        self.max_retries = None
        self.name = None
        self.extension = None
        self._create_user = None
        self.receive = None
        self._last_modified_user = None
        self.interval = None
        self.url = None
        self.timeout = None
        self._last_modified_time = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)