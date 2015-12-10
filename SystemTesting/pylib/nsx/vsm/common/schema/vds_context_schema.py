import base_schema
from switch_schema import SwitchSchema

class VDSContextSchema(base_schema.BaseSchema):
    _schema_name = "vdsContext"
    def __init__(self, py_dict = None):
        """Constructor"""
        super(VDSContextSchema, self).__init__()
        self._attributeName = 'class'
        self._attributeValue = "vdsContext"
        self.set_data_type('xml')
        self.switch = SwitchSchema()
        self.mtu  = None
        self.teaming  = None

        if py_dict != None:
            self.get_object_from_py_dict(py_dict)
