import base_schema

class VXLANControllerCredentialSchema(base_schema.BaseSchema):
    _schema_name = "controllerCredential"
    def __init__(self, py_dict = None):
        """ Constructor to create VXLANControllerCredentialSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VXLANControllerCredentialSchema, self).__init__()
        self.set_data_type('xml')
        self.apiPassword = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
