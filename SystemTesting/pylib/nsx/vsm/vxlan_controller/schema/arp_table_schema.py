import base_cli_schema
from horizontal_data_parser import HorizontalTableParser


class ARPTableSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ARPTableSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser      = HorizontalTableParser()

    def __init__(self, py_dict=None):
        """ Constructor to create ARPTableSchema object

        """
        super(ARPTableSchema, self).__init__()
        self.table = [ARPTableEntrySchema()]

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



class ARPTableEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ARPTableEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create ARPTableEntrySchema object

        """
        super(ARPTableEntrySchema, self).__init__()
	# values of the attributes are the strings which stdout uses to dump data
	# Because stdout uses stuff like Connection-ID we cannot have same attributes
	# as an attribute cannot have '-' in it

        self.vni = "VNI"
        self.ip  = "IP"
        self.mac = "MAC"
        self.connection_id = "Connection-ID"




if __name__ == '__main__':
   schema = ARPTableSchema()
