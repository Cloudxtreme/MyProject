import vmware.common.base_schema as base_schema

class PortgroupSchema(base_schema.BaseSchema):

    def __init__(self, name, vlan_id, vswitch_name):
        self.name = name
        self.vlan = vlan_id
        self.switch = vswitch_name
