import base_schema

class VXLANControllerConfigSchema(base_schema.BaseSchema):
    _schema_name = "controllerConfig"
    def __init__(self, py_dict = None):
        """ Constructor to create VXLANControllerConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VXLANControllerConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.sslEnabled = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

