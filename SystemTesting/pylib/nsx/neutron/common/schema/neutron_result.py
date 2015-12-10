import error
import base_schema
from error_data import ErrorData

class Result(base_schema.BaseSchema):
    def __init__(self):
        super(Result, self).__init__()
        self.status_code = None
        self.details = None
        self.errorCode = None
        self.errorData = ErrorData()

