from appliances_schema import AppliancesSchema
import base_schema
from interfaces_schema import InterfacesSchema
from vsm_vnic_schema import VnicSchema
from mgmt_interface_schema import MgmtInterfaceSchema

class NSXEdgeSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "edge"
    def __init__(self, py_dict=None, version='3.0'):
        """ Constructor to create EdgeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXEdgeSchema, self).__init__()
        self.id                   = None
        self.version              = None
        self.description          = None
        self.status               = None
        self.datacenterMoid       = None
        self.datacenterName       = None
        self.name                 = None
        self.fqdn                 = None
        self.tenant               = None
        self.type                 = None
        self.appliances           = AppliancesSchema()
        self.vnics                = [VnicSchema()]
        print ("nsx_edge_schema version: %s self.version: %s \n" % (version, self.version))
        self.set_data_type("xml")

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
