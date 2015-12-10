import base_schema

class NeutronStatusSchema(base_schema.BaseSchema):
    _schema_name = "neutronstatus"

    def __init__(self, py_dict=None):

        super(NeutronStatusSchema, self).__init__()
        self.TasksStatus = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
