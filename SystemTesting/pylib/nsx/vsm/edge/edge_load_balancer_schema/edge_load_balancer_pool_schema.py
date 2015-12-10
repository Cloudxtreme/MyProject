import base_schema
from edge_load_balancer_pool_member_schema import LoadBalancerPoolMemberSchema

class LoadBalancerPoolSchema(base_schema.BaseSchema):
    _schema_name = "pool"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerPoolSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerPoolSchema, self).__init__()
        self.set_data_type('xml')
        self.poolId = None
        self.name = None
        self.description = None
        self.snatEnable = None
        self.algorithm = None
        self.monitorId = None
        self.memberArray = [LoadBalancerPoolMemberSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
