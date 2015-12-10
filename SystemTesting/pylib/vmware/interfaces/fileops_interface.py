class FileOpsInterface(object):
    """Interface for file operations."""

    @classmethod
    def syslog_append(cls, client_object, syslog_message=None):
        raise NotImplementedError

    @classmethod
    def file_append(cls, client_object, file_name=None, append_string=None,
                    size=None):
        raise NotImplementedError

    @classmethod
    def file_find_context(cls, client_object, file_name=None,
                          start_str=None, end_str=None):
        raise NotImplementedError

    @classmethod
    def query_file(cls, client_object, file_name=None, grep_after=None,
                   grep_string=None, max_wait=None, interval=None,
                   pattern=None, count=None):
        raise NotImplementedError

    @classmethod
    def find_pattern_count(cls, client_object, file_name=None,
                           grep_string=None, grep_after=None, pattern=None):
        raise NotImplementedError

    @classmethod
    def delete_file(cls, client_object, file_name=None):
        raise NotImplementedError

    @classmethod
    def download_files(cls, client_object, resource=None, destination=None):
        raise NotImplementedError

    @classmethod
    def copy_file(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def move_file(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def remove_file(cls, client_object, options=None,
                    file_name=None, timeout=None):
        raise NotImplementedError

    @classmethod
    def get_dict_from_json_file(cls, client_obj, file_name=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete_backend_file(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def check_cluster_backup_file(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def check_node_backup_file(cls, client_obj, **kwargs):
        raise NotImplementedError
