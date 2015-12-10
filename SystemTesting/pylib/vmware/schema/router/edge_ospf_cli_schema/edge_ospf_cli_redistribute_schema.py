import vmware.common.base_schema_v2 as base_schema_v2
import vmware.schema.router.ospf_cli_redistribute_rule_schema as ospf_cli_redistribute_rule_schema  # noqa


class OspfCliRedistributeSchema(base_schema_v2.BaseSchema):
    rules = (ospf_cli_redistribute_rule_schema.OspfCliRedistributeRuleSchema,)
    enabled = None
