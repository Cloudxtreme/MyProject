import base_schema

class VersionedDeploymentSpecSchema(base_schema.BaseSchema):
    _schema_name = "versionedDeploymentSpec"

    def __init__(self, py_dict=None):
        """ Constructor to create VersionedDeploymentSpecSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(VersionedDeploymentSpecSchema, self).__init__()
        self.set_data_type('xml')
        self.hostVersion = None
        self.ovfUrl = None
        self.vmciEnabled = None
        self._partial_endpoint = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)