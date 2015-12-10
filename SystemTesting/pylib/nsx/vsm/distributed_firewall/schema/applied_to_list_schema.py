import base_schema
from applied_to_schema import AppliedToSchema

class AppliedToListSchema(base_schema.BaseSchema):
    _schema_name = "appliedToList"

    def __init__(self, py_dict=None):
        """ Constructor to create AppliedToListSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(AppliedToListSchema, self).__init__()
        self.set_data_type("xml")
        self.appliedTo = [AppliedToSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
