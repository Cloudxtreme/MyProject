import vmware.nsx_api.appliance.node.postnodesyslogexporter \
    as postnodesyslogexporter
import vmware.nsx_api.appliance.node.schema \
    .nodesyslogexporterproperties_schema as nodesyslogexporterproperties_schema
import vmware.nsx_api.appliance.node.schema \
    .nodesyslogexporterpropertieslistresult_schema \
    as nodesyslogexporterpropertieslistresult_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    #  Attribute map
    _attribute_map = {
        'id_': 'exporter_name',
    }

    _client_class = postnodesyslogexporter.PostNodeSyslogExporter
    _schema_class = nodesyslogexporterproperties_schema \
        .NodeSyslogExporterPropertiesSchema
    _list_schema_class = nodesyslogexporterpropertieslistresult_schema \
        .NodeSyslogExporterPropertiesListResultSchema
