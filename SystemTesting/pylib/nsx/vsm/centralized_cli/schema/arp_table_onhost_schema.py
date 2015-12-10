import base_cli_schema
import vmware.parsers.vertical_table_parser as vertical_table_parser


class ARPTableOnHostSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ARPTableOnHostSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser      = vertical_table_parser.VerticalTableParser()

    def __init__(self, py_dict=None):
        """ Constructor to create ARPTableOnHostSchema object

        """
        super(ARPTableOnHostSchema, self).__init__()
        self.table = ARPCountEntrySchema()

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
        arpcountentryObj = ARPCountEntrySchema()
        arpcountentryObj.arpEntryList = []
        table = py_dict[py_dict.keys()[0]]
        arpcountentryObj.arpEntryCount = table.keys()[0][1]
        tb_arpentrylist = table[table.keys()[0]]
        for entry in tb_arpentrylist:
            arpentrylist = ARPEntryListSchema()
            arpentrylist.index = entry[1]
            arpentrydetail = tb_arpentrylist[entry]
            arpEntry = ARPEntrySchema()
            for key in arpentrydetail:
                if key == 'mac':
                    arpEntry.mac = arpentrydetail[key]
                elif key == 'ip':
                    arpEntry.ip = arpentrydetail[key]
                else:
                    arpEntry.flags = arpentrydetail[key]

            arpentrylist.arpEntry = []
            arpentrylist.arpEntry.append(arpEntry)
            arpcountentryObj.arpEntryList.append(arpentrylist)

        self.table = arpcountentryObj

class ARPCountEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ARPCountEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create ARPCountEntrySchema object

        """
        super(ARPCountEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.arpEntryCount = "ARP entry count"
        self.arpEntryList = [ARPEntryListSchema()]

class ARPEntryListSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ARPEntryListSchema"
    def __init__(self, py_dict=None):
        """ Constructor to create ARPEntryListSchema object

        """
        super(ARPEntryListSchema, self).__init__()
        self.index = "index"
        self.arpEntry = [ARPEntrySchema()]

class ARPEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ARPEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create ARPEntrySchema object

        """
        super(ARPEntrySchema, self).__init__()
        # values of the attributes are the strings which stdout uses to dump data
        # Because stdout uses stuff like Connection-ID we cannot have same attributes
        # as an attribute cannot have '-' in it

        self.ip = "IP"
        self.mac = "MAC"
        self.flags = "Flags"

if __name__ == '__main__':
    schema = ARPTableOnHostSchema()
