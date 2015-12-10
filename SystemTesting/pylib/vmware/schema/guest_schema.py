import vmware.common.base_schema as base_schema


class GuestSchema(base_schema.BaseSchema):

    def __init__(self, name=None, family=None, guest_id=None,
                 state=None, hostname=None, ip=None):

        self.name = name
        self.family = family
        self.guest_id = guest_id
        self.state = state
        self.hostname = hostname
        self.ip = ip
