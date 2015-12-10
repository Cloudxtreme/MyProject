import base_schema
from edge_cli_json_parser import EdgeCliJsonParser
from edge_ospf_cli_area_schema import OspfCliAreaSchema
from edge_ospf_cli_redistribute_schema import OspfCliRedistributeSchema

class EdgeCliOspfSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "edgeOspfSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser = EdgeCliJsonParser()

    def __init__(self, py_dict=None):
        """ Constructor to create EdgeOSPFSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeCliOspfSchema, self).__init__()
        self.defaultOriginate = None
        self.forwardingAddress = None
        self.gracefulRestart = None
        self.protocolAddress = None
        self.enabled = None
        self.areas = [OspfCliAreaSchema()]
        self.redistribute = OspfCliRedistributeSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def set_data_raw(self, raw_payload):
        """ Convert raw data to py_dict based on the class parser and assign the py_dict to class element so that
        get_object_from_py_dict() can take it from there.

        @param raw_payload raw string from which python objects are constructed after parsing the string
        """

        payload = self._parser.get_parsed_data(raw_payload, 'ospf')
        print "PAYLOAD = %s" %payload


        if payload != "FAILURE":
            py_dict = payload
        else:
            py_dict = None

        print "PYDICT = %s" % py_dict

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict['ospf'])
        return
