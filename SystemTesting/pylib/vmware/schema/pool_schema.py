import vmware.common.base_schema as base_schema


class PoolSchema(base_schema.BaseSchema):

    def __init__(self, name=None):
        self.name = name
