class TrafficVerificationInterface(object):
    """Interface class to implement traffic verification related operations."""

    @classmethod
    def generate_capture_file_name(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def start_capture(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def stop_capture(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def extract_capture_results(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete_capture_file(cls, client_object, **kwargs):
        raise NotImplementedError
