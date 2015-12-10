import base_schema


class NSXManagerStatusSchema(base_schema.BaseSchema):
    _schema_name = "nsxManagerStatus"

    def __init__(self, py_dict=None):
        """ Constructor to create IPSet object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXManagerStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.vsmId = None
        self.lastSuccessfulSyncTime = None
        self.syncState = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

