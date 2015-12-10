import base_schema

class MgmtConnCredentialSchema(base_schema.BaseSchema):
    _schema_name = "mgmtconncredential"

    def __init__(self, py_dict=None):
        """ Constructor to create MgmtConnCredentialSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(MgmtConnCredentialSchema, self).__init__()
        self.type = None
        self.pem_encoded = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
