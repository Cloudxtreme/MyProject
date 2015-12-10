import base_schema
from key_value_schema import KeyValueSchema

class DeploymentContainerSchema(base_schema.BaseSchema):
    _schema_name = "deploymentContainer"
    def __init__(self, py_dict=None):
        """ Constructor to create DeploymentContainerSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DeploymentContainerSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.hypervisorType = None
        self.containerattributes = [KeyValueSchema()]

        self.objectId = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
