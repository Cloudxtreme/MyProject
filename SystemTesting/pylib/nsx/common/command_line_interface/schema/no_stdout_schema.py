import base_cli_schema

class NoStdOutSchema(base_cli_schema.BaseCLISchema):
    _schema_name = "NoStdOutSchema"
    # No parsing required as output does not contain anything
    _parser      = None

    def __init__(self, py_dict=None):
        super(NoStdOutSchema, self).__init__()
        self.stdout = None



    def set_data_raw(self, raw_payload):
        """ Convert raw data to schema object attribute.

        @param raw_payload
        """
        # set the values of raw_payload in stdout attribute
        self.stdout = raw_payload
        return self
