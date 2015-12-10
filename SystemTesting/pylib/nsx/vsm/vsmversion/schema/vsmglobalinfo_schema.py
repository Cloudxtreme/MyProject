import base_schema
from vsmversion_schema import VSMVersionInfoSchema

class VSMGlobalInfoSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
       This schema is only use to GET global information
    """
    _schema_name = "globalInfo"
    def __init__(self, py_dict=None):
        super(VSMGlobalInfoSchema, self).__init__()
        self.currentLoggedInUser = ""
        self.versionInfo = VSMVersionInfoSchema()
        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

