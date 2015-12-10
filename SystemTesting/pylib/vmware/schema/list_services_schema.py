import vmware.common.base_schema as base_schema


class ListServicesSchema(base_schema.BaseSchema):
    _schema_name = "ServicesSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListServicesSchema object
        """
        super(ListServicesSchema, self).__init__()
        self.table = [ServicesEntrySchema()]
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ServicesEntrySchema(base_schema.BaseSchema):
    _schema_name = "ServiceEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ServicesEntrySchema object
        """
        super(ServicesEntrySchema, self).__init__()
        self.service_name = None
        self.service_state = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)