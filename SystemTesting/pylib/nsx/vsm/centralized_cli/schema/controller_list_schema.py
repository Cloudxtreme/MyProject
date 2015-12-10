import base_cli_schema
from horizontal_data_parser import HorizontalTableParser


class ControllerListSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ControllerListSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser      = HorizontalTableParser()

    def __init__(self, py_dict=None):
        """ Constructor to create ControllerListSchema object

        """
        super(ControllerListSchema, self).__init__()
        self.table = [ControllerEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def set_data_raw(self, raw_payload):
        """ Convert raw data to py_dict based on the class parser and assign
	          the py_dict to class element so that get_object_from_py_dict()
	          can take it from there.
        @param raw_payload raw string from which python objects are constructed
               after	parsing the string
        """

        payload = self._parser.get_parsed_data(raw_payload)
        py_dict = {'table': payload}
        return self.get_object_from_py_dict(py_dict)


class ControllerEntrySchema(base_cli_schema.BaseCLISchema):
    _schema_name = "ControllerEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create ControllerEntrySchema object
        """
        super(ControllerEntrySchema, self).__init__()

        self.name = "NAME"
        self.ip = "IP"
        self.state = "State"


if __name__ == '__main__':
   schema = ControllerListSchema()
