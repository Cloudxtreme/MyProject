import vmware.common.base_schema as base_schema


class SwitchSchema(base_schema.BaseSchema):

    def __init__(self, switch=None, numports=None, numports_available=None,
                 confports=None, mtu=None, uplink=None):

        self.switch = switch
        self.numports = numports
        self.numports_available = numports_available
        self.confports = confports
        self.usedports = numports - numports_available
        self.mtu = mtu
        self.uplink = uplink
