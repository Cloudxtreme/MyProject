class CRUDInterface(object):

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def read(cls, client_obj, obj_id=None, server_form=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def update(cls, client_obj, obj_id=None, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete(cls, client_obj, obj_id=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_id(cls, client_obj, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_id_from_schema(cls, client_obj, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def query(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_transport_nodes(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def status(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_allocations(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_key_sizes(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def download(cls, client_obj, obj_id=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_node_id(cls, client_obj, obj_id=None, **kwargs):
        """
        Gets the node id of nsx manager by querying the cluster
        node
        """
        raise NotImplementedError

    @classmethod
    def get_base_url(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_certificate(cls, client_obj, **kwargs):
        raise NotImplementedError
