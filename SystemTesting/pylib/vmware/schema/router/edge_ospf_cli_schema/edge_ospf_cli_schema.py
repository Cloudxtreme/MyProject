import vmware.common.base_schema_v2 as base_schema_v2
import vmware.parsers.edge_cli_json_parser as edge_cli_json_parser

import vmware.schema.router.edge_ospf_cli_area_schema as edge_ospf_cli_area_schema  # noqa
import vmware.schema.router.edge_ospf_cli_redistribute_schema as edge_ospf_cli_redistribute_schema  # noqa


class EdgeCliOspfSchema(base_schema_v2.BaseSchema):

    defaultOriginate = None
    forwardingAddress = None
    gracefulRestart = None
    protocolAddress = None
    enabled = None
    areas = (edge_ospf_cli_area_schema.OspfCliAreaSchema,)
    redistribute = (edge_ospf_cli_redistribute_schema.OspfCliRedistributeSchema,)  # noqa
    _parser = edge_cli_json_parser.EdgeCliJsonParser()
