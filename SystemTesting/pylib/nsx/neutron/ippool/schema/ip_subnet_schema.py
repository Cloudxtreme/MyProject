import base_schema
from static_route_schema import StaticRouteSchema
from allocation_range_schema import AllocationRangeSchema

class IpSubnetSchema(base_schema.BaseSchema):
    _schema_name = "ipsubnet"

    def __init__(self, py_dict=None):
        """ Constructor to create IpSubnetSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IpSubnetSchema, self).__init__()
        self.comment = None
        self.static_routes = [StaticRouteSchema()]
        self.allocation_ranges = [AllocationRangeSchema()]
        self.dns_nameservers = [str]
        self.gateway_ip = None
        self.ip_version = None
        self.cidr = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)