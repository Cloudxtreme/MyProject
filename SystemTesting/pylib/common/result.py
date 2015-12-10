import error


class Result:
    def __init__(self):
        self.status_code = None
        self.response = None
        self.error = None
        self.reason = None
        self.response_data = None
        self.is_result_object = True

    def set_status_code(self, status_code):
        self.status_code = status_code

    def get_status_code(self):
        return self.status_code

    def set_error(self, payload, reason):
        self.error = payload
        self.reason = reason

    def set_response(self, response):
        self.response = response

    def get_response(self):
        return self.response

    def set_response_data(self, response_data):
        self.response_data = response_data

    def get_response_data(self):
        return self.response_data

    def set_is_result_object(self, is_result_object):
        self.is_result_object = is_result_object

    def get_is_result_object(self):
        return self.is_result_object
