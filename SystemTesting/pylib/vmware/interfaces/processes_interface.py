class ProcessesInterface(object):
    """Interface for processes operations."""

    @classmethod
    def kill_processes_by_name(cls, client_object, options=None,
                               process_name=None):
        raise NotImplementedError