import base_schema

class ErrorData(base_schema.BaseSchema):
    def __init__(self):
        super(ErrorData, self).__init__()
        self.thumbprint = None
