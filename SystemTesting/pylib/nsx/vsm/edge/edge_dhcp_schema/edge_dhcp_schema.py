import base_schema
from static_binding_schema import StaticBindingSchema
from vsm_ip_pool_schema import IPPoolSchema
from logging_schema import LoggingSchema

class DHCPSchema(base_schema.BaseSchema):
    _schema_name = "dhcp"
    def __init__(self, py_dict=None):
        """ Constructor to create DHCPSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DHCPSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.staticBindings = [StaticBindingSchema()]
        self.ipPools = [IPPoolSchema()]
        self.logging = LoggingSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)