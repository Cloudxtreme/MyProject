import vmware.common.base_schema_v2 as base_schema_v2


class PortTeamingInfoTableEntrySchema(base_schema_v2.BaseSchema):
    """Schema for a results table entry with Port teaming information."""

    port = None
    load_balancing = None
    link_selection = None
    link_behavior = None
    active = None
    standby = None


class PortTeamingInfoTableSchema(base_schema_v2.BaseSchema):
    """Schema for a results table with Port teaming information."""

    table = (PortTeamingInfoTableEntrySchema,)
