"""Interface class to implement logging server related operations."""


class LogServerInterface(object):

    @classmethod
    def verify_audit_logs(cls, client_object, **kwargs):
        raise NotImplementedError
