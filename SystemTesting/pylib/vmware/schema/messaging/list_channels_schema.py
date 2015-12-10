import vmware.common.base_schema as base_schema


class ListChannelsSchema(base_schema.BaseSchema):
    _schema_name = "ListChannelsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListChannelsSchema object
        """
        super(ListChannelsSchema, self).__init__()
        self.table = [ChannelsEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ChannelsEntrySchema(base_schema.BaseSchema):
    _schema_name = "ChannelsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ChannelsEntrySchema object
        """
        super(ChannelsEntrySchema, self).__init__()

        self.pid = None
        self.user = None
        self.consumer_count = None
        self.messages_unacknowledged = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
