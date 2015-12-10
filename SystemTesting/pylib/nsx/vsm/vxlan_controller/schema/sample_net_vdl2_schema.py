import base_cli_schema
from vertical_data_parser import VerticalTableParser


class NetVdl2Schema(base_cli_schema.BaseCLISchema):
    _schema_name = "NetVdl2Schema"
    # Select the parser appropriate for the stdout related to this command
    _parser      = VerticalTableParser()

    def __init__(self, py_dict=None):
        """ Constructor to create NetVdl2Schema object

        """
        super(NetVdl2Schema, self).__init__()
        self.table = [Vdl2EntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def set_data_raw(self, raw_payload):
        """ Convert raw data to py_dict based on the class parser and
        assign the py_dict to class element so that get_object_from_py_dict()
        can take it from there.

        @param raw_payload raw string from which python objects are constructed after
        parsing the string
        """
        payload = self._parser.get_parsed_data(raw_payload)
        py_dict = {'table': payload}
        return self.get_object_from_py_dict(py_dict)


class Vdl2EntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "Vdl2EntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create Vdl2EntrySchema object

        """
        super(Vdl2EntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        # self.globalState = GlobalStateEntrySchema()
        self.vxlanVds = [VxlanVdsEntrySchema()]

class VxlanVdsEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VxlanVdsEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VxlanVdsEntrySchema object

        """
        super(VxlanVdsEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.vdsName      = "VXLAN VDS"
        self.vdsId        = "VDS ID"
        self.mtu          = "MTU"
        self.segmentId    = "Segment ID"
        self.gatewayIP    = "Gateway IP"
        self.gatewayMac   = "Gateway MAC"
        self.vmknicCount  = [VmknicCountEntrySchema()]
        self.networkCount = [NetworkCountEntrySchema()]

class VmknicCountEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VmknicCountEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VmknicCountEntrySchema object

        """
        super(VmknicCountEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.vmknicCount = "Vmknic count"
        self.vxlanVmknic = [VxlanVmknicEntrySchema()]


class VxlanVmknicEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VxlanVmknicEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VxlanVmknicEntrySchema object

        """
        super(VxlanVmknicEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.vmknicName   = "VXLAN vmknic"
        self.vdsPortId    = "VDS port ID"
        self.switchPortId = "Switch port ID"
        self.vlanId       = "VLAN ID"
        self.ip           = "IP"
        self.segmentId    = "Segment ID"

class NetworkCountEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "NetworkCountEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create NetworkCountEntrySchema object

        """
        super(NetworkCountEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.networkCount = "Network count"
        self.vxlanNetwork = [VxlanNetworkEntrySchema()]

class VxlanNetworkEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VxlanNetworkEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VxlanNetworkEntrySchema object

        """
        super(VxlanNetworkEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.networkName  = "VXLAN network"
        self.multicastIP  = "Multicast IP"
        self.controlPlane = "Control plane"
        self.controller   = "Controller"

if __name__ == '__main__':
    schema = NetVdl2Schema()
