class Result(object):

    def __init__(self, status_code=None, error=None,
                 reason=None, response_data=None):
        self.status_code = status_code
        self.error = error
        self.reason = reason
        self.response_data = response_data
