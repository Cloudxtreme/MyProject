import vmware.common.base_schema as base_schema


class ListConnectionsSchema(base_schema.BaseSchema):
    _schema_name = "ListConnectionsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListConnectionsSchema object
        """
        super(ListConnectionsSchema, self).__init__()
        self.table = [ConnectionsEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ConnectionsEntrySchema(base_schema.BaseSchema):
    _schema_name = "ConnectionsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ConnectionsEntrySchema object
        """
        super(ConnectionsEntrySchema, self).__init__()

        self.user = None
        self.peer_host = None
        self.peer_port = None
        self.state = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
