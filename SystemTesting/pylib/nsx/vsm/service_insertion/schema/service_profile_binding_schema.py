import base_schema
from distributed_virtual_port_groups_schema import DistributedVirtualPortGroupsSchema
from service_profile_binding_virtual_wires_schema import VirtualWiresSchema

class ServiceProfileBindingSchema(base_schema.BaseSchema):
    _schema_name = "serviceProfileBinding"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceProfileBindingSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceProfileBindingSchema, self).__init__()
        self.set_data_type('xml')
        self.distributedVirtualPortGroups = DistributedVirtualPortGroupsSchema()
        self.virtualWires = VirtualWiresSchema()
        self.excludedVnics = None
        self.virtualServers = None
        self._partial_endpoint = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
