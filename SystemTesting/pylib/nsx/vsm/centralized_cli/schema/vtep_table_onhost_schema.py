import base_cli_schema
import vmware.parsers.vertical_table_parser as vertical_table_parser


class VTEPTableOnHostSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VTEPTableOnHostSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser      = vertical_table_parser.VerticalTableParser()

    def __init__(self, py_dict=None):
        """ Constructor to create VTEPTableOnHostSchema object

        """
        super(VTEPTableOnHostSchema, self).__init__()
        self.table = VTEPCountEntrySchema()

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
        return self.get_object_from_py_dict(payload)

    def get_object_from_py_dict(self, py_dict):
        """ Method to fill the current schema object with values from a py_dict
            Its behavior is slightly different from parent in the sense that the py_dict
            elements are not same as the schema class attributes but the py_dict elements
            are same as the value of the schema class attributes

            @param py_dict   dict object to get values from
        """
        vtepcountentryObj = VTEPCountEntrySchema()
        vtepcountentryObj.vtepEntryList = []
        table = py_dict[py_dict.keys()[0]]
        vtepcountentryObj.vtepEntryCount = table.keys()[0][1]
        tb_vtepEntryCount = table[table.keys()[0]]
        for entry in tb_vtepEntryCount:
            vtepentrydetail = tb_vtepEntryCount[entry]
            vtepEntry = VTEPEntrySchema()
            for key in vtepentrydetail:
                if key == 'segment id':
                    vtepEntry.segmentid = vtepentrydetail[key]
                elif key == 'vtep ip':
                    vtepEntry.vtepip = vtepentrydetail[key]
                else:
                    vtepEntry.flags = vtepentrydetail[key]

            vtepEntryCount = VTEPEntryListSchema()
            vtepEntryCount.index = entry[1]
            vtepEntryCount.vtepEntry =[]
            vtepEntryCount.vtepEntry.append(vtepEntry)
            vtepcountentryObj.vtepEntryList.append(vtepEntryCount)
        self.table = vtepcountentryObj


class VTEPCountEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VTEPCountEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VTEPCountEntrySchema object

        """
        super(VTEPCountEntrySchema, self).__init__()
        self.vtepEntryCount = "VTEP count"
        self.vtepEntryList = [VTEPEntryListSchema()]

class VTEPEntryListSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VTEPEntryListSchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VTEPEntryListSchema object

        """
        super(VTEPEntryListSchema, self).__init__()
        self.index = "index"
        self.vtepEntry = [VTEPEntrySchema()]

class VTEPEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "VTEPEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create VTEPEntrySchema object

        """
        super(VTEPEntrySchema, self).__init__()
        self.segmentid = "segment id"
        self.vtepip = "vtep ip"
        self.flags = "flags"

if __name__ == '__main__':
    schema = VTEPTableOnHostSchema()
