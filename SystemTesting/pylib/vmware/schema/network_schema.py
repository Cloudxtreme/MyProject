import vmware.common.base_schema as base_schema


class NetworkSchema(base_schema.BaseSchema):

    def __init__(self, name=None, switch=None, vlan=None,
                 auto_expand=None, description=None,
                 numports=None, portgroup_type=None,
                 resource_pool=None):
        self.name = name
        self.switch = switch
        self.vlan = vlan
        self.auto_expand = auto_expand
        self.description = description
        self.numports = numports
        self.portgroup_type = portgroup_type
        self.resource_pool = resource_pool
        # portgroup_type can be earlyBinding, lateBinding, ephemeral
