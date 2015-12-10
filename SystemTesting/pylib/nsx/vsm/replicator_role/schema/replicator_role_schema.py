import base_schema

class ReplicatorRoleSchema(base_schema.BaseSchema):
    _schema_name = "universalSyncRole"
    def __init__(self, py_dict=None):
        super(ReplicatorRoleSchema, self).__init__()
        self.set_data_type('xml')
        self.role = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
