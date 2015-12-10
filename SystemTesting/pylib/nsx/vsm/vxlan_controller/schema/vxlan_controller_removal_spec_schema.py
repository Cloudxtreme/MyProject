import base_schema

class VXLANControllerRemovalSpecSchema(base_schema.BaseSchema):
    _schema_name = "vxlanControllerRemovalSpec"
    def __init__(self, py_dict = None):
        """ Constructor to create VXLANControllerRemovalSpecSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VXLANControllerRemovalSpecSchema, self).__init__()
        self.set_data_type('xml')
        self.forceRemovalForLast = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


