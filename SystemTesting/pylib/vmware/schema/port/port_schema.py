import vmware.common.base_schema_v2 as base_schema_v2


class PortQosInfoTableEntrySchema(base_schema_v2.BaseSchema):
    """Schema for a results table entry with Port QoS information."""

    port = None
    average_bandwidth = None
    peak_bandwidth = None
    burst_size = None
    class_of_service = None
    dscp = None
    mode = None


class PortQosInfoTableSchema(base_schema_v2.BaseSchema):
    """Schema for a results table with Port QoS information."""

    table = (PortQosInfoTableEntrySchema,)
