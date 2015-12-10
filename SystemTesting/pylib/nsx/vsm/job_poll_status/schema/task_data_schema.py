import base_schema
from entry_schema import EntrySchema


class TaskDataSchema(base_schema.BaseSchema):
    _schema_name = "taskData"
    def __init__(self, py_dict=None):
        """ Constructor to create TaskDataSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TaskDataSchema, self).__init__()
        self.set_data_type('xml')
        self.entry = EntrySchema()
