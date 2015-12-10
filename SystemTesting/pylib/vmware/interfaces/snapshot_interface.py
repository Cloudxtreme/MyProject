"""Interface class to implement Snapshot operations associated with a client"""


class SnapshotInterface(object):

    @classmethod
    def restore(cls, client_object, **kwargs):
        """Interface to restore on NSXManager"""
        raise NotImplementedError

    @classmethod
    def download(cls, client_object, **kwargs):
        """Interface to download snapshot file from NSXManager"""
        raise NotImplementedError