import base_schema


class FirewallGlobalConfigSchema(base_schema.BaseSchema):
    _schema_name = "globalConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallGlobalConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallGlobalConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.tcpPickOngoingConnections = None
        self.tcpAllowOutOfWindowPackets = None
        self.tcpSendResetForClosedVsePorts = None
        self.dropInvalidTraffic = None
        self.logInvalidTraffic = None
        self.tcpTimeoutOpen = None
        self.tcpTimeoutEstablished = None
        self.tcpTimeoutClose = None
        self.udpTimeout = None
        self.icmpTimeout = None
        self.icmp6Timeout = None
        self.ipGenericTimeout = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)