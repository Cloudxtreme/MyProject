import base_cli_schema
import vmware.parsers.vertical_table_parser as vertical_table_parser


class MACTableOnHostSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "MACTableOnHostSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser      = vertical_table_parser.VerticalTableParser()

    def __init__(self, py_dict=None):
        """ Constructor to create MACTableOnHostSchema object

        """
        super(MACTableOnHostSchema, self).__init__()
        self.table = MACCountEntrySchema()

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

        maccountentryObj = MACCountEntrySchema()
        maccountentryObj.macEntryList = []
        table = py_dict[py_dict.keys()[0]]
        maccountentryObj.macEntryCount = table.keys()[0][1]
        tb_macentrylist = table[table.keys()[0]]
        for entry in tb_macentrylist:
            macentrylist = MACEntryListSchema()
            macentrylist.index = entry[1]
            macentrydetail = tb_macentrylist[entry]
            macEntry = MACEntrySchema()
            for key in macentrydetail:
                if key == 'inner mac':
                    macEntry.innerMac = macentrydetail[key]
                elif key == 'outer ip':
                    macEntry.outerIp = macentrydetail[key]
                elif key == 'outer mac':
                    macEntry.outerMac = macentrydetail[key]
                else:
                    macEntry.flags = macentrydetail[key]

            macentrylist.macEntry = []
            macentrylist.macEntry.append(macEntry)
            maccountentryObj.macEntryList.append(macentrylist)

        self.table = maccountentryObj


class MACCountEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "MACCountEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create MACCountEntrySchema object

        """
        super(MACCountEntrySchema, self).__init__()
        self.macEntryCount = "mac entry count"
        self.macEntryList = [MACEntryListSchema()]

class MACEntryListSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "MACEntryListSchema"
    def __init__(self, py_dict=None):
        """ Constructor to create MACEntryListSchema object

        """
        super(MACEntryListSchema, self).__init__()
        self.index = "index"
        self.macEntry = [MACEntrySchema()]

class MACEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "MACEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create MACEntrySchema object

        """
        super(MACEntrySchema, self).__init__()
        self.innerMac = "inner mac"
        self.outerMac = "outer mac"
        self.outerIp = "outer ip"
        self.flags = "flags"

if __name__ == '__main__':
    schema = MACTableOnHostSchema()
