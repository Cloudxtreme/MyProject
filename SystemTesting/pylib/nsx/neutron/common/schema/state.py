import base_schema
from state_details import StateDetailsSchema

class StateSchema(base_schema.BaseSchema):
    _schema_name = "state"

    def __init__(self, py_dict=None):
        """ Constructor to create State object for all endpoints in Neutron

        @param py_dict : python dictionary to construct this object
        """
        super(StateSchema, self).__init__()
        self.details = [StateDetailsSchema()]
        self.state = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
