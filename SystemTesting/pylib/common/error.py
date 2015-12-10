import base_schema


class Error(base_schema.BaseSchema):
    _schema_name = "error"

    def __init__(self, py_dict=None):
        super(Error, self).__init__()
        self.set_data_type('xml')
        self.details = None
        self.errorCode = None
        self.moduleName = None
        self.reason = None

    def set_reason(self, reason):
        self.reason = reason

    def get_details(self):
        return self.details

    def get_error_code(self):
        return self.errorCode

    def get_reason(self):
        return self.reason
