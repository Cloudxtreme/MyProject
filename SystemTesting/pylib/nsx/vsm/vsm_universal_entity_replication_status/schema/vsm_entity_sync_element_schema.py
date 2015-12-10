import base_schema


class VSMEntitySyncElementSchema(base_schema.BaseSchema):
    _schema_name = "entitySyncElement"

    def __init__(self, py_dict=None):
        """ Constructor to replication status for an entity

        @param py_dict : python dictionary to construct this object
        """
        super(VSMEntitySyncElementSchema, self).__init__()
        self.set_data_type('xml')
        self.vsmId = None
        self.objectExists = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

