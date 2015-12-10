import vmware.common.base_schema_v2 as base_schema_v2


class OspfCliAreaSchema(base_schema_v2.BaseSchema):
    areaId = None
    authenticationType = None
    authenticationSecret = None
    type_ = None
