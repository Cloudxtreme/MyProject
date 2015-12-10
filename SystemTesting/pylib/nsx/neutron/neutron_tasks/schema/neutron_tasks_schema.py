import base_schema
from neutron_status_schema import NeutronStatusSchema

class NeutronTasksSchema(base_schema.BaseSchema):
    _schema_name = "neutrontasks"

    def __init__(self, py_dict=None):

        super(NeutronTasksSchema, self).__init__()
        self.cancelable = None
        self.message = None
        self.progress = None
        self.request_method = None
        self.status = None
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
