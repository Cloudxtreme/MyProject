import base_schema

class NeutronTasksResponseSchema(base_schema.BaseSchema):
    _schema_name = "neutrontasksresponse"

    def __init__(self, py_dict=None):

        super(NeutronTasksResponseSchema, self).__init__()
        self.id = None
        self.host_address = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
