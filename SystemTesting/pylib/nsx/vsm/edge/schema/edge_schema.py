import base_schema
from query_daemon_schema import QueryDaemonSchema
from auto_configuration_schema import AutoConfigurationSchema
from cli_settings_schema import CLISettingsSchema
from appliances_schema import AppliancesSchema
from interfaces_schema import InterfacesSchema
from mgmt_interface_schema import MgmtInterfaceSchema
from vnic_schema import VNICSchema
from features_schema import FeaturesSchema


class EdgeSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "edge"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeSchema, self).__init__()
        self.set_data_type("xml")
        self.id = None
        self.version = None
        self.description = None
        self.status = None
        self.datacenterMoid = None
        self.datacenterName = None
        self.tenant = None
        self.name = None
        self.fqdn = None
        self.enableAesni = None
        self.enableFips = None
        self.vseLogLevel = None
        self.vnics = [VNICSchema()]
        self.appliances = AppliancesSchema()
        self.cliSettings = CLISettingsSchema()
        self.features = FeaturesSchema()
        self.autoConfiguration = AutoConfigurationSchema()
        self.type = None
        self.mgmtInterface = MgmtInterfaceSchema()
        self.interfaces = InterfacesSchema()
        self.hypervisorAssist = None
        self.edgeAssistId = None
        self.queryDaemon = QueryDaemonSchema()
        self.localEgressEnabled = None
        self.globalConfigRevision = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
