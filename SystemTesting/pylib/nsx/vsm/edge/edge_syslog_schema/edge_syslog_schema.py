import base_schema
from edge_syslog_server_addresses_schema import SysLogServerAddressesSchema


class SysLogSchema(base_schema.BaseSchema):
    _schema_name = "syslog"
    def __init__(self, py_dict=None):
        """ Constructor to create SysLogSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SysLogSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.protocol = None
        self.serverAddresses = SysLogServerAddressesSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)