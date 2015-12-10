import base_schema

class DeploymentScopeSchema(base_schema.BaseSchema):
    _schema_name = "set"

    def __init__(self, py_dict=None):
        """ Constructor to create DeploymentScopeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DeploymentScopeSchema, self).__init__()
        self.set_data_type('xml')
        self.string = None
        self.id = None #Here id is used because in base_client

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)