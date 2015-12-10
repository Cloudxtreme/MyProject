import vmware.common.base_schema as base_schema


class ListExchangesSchema(base_schema.BaseSchema):
    _schema_name = "ListExchangesSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListExchangesSchema object
        """
        super(ListExchangesSchema, self).__init__()
        self.table = [ExchangesEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ExchangesEntrySchema(base_schema.BaseSchema):
    _schema_name = "ExchangesEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ExchangesEntrySchema object
        """
        super(ExchangesEntrySchema, self).__init__()

        self.name = None
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)