class TroubleshootInterface(object):
    """Interface class to implement trouble shooting related operations."""

    @classmethod
    def copy_tech_support(cls, client_object, logdir=None, collectorIP=None):
        """Method to copy tech support bundle to the launcher."""
        raise NotImplementedError

    @classmethod
    def collect_logs(cls, client_object, logdir=None):
        """Method to copy logs from test host to logdir in launcher."""
        raise NotImplementedError
