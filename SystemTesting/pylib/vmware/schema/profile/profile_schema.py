import vmware.common.base_schema as base_schema


class ProfileSchema(base_schema.BaseSchema):

    def __init__(self, name=None, annotation=None, enabled=None):
        self.name = name
        self.annotation = annotation
        self.enabled = enabled
