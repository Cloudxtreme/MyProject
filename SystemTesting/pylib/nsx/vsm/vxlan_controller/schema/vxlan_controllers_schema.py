import base_schema
from controller_schema import controllerSchema
class VXLANControllersSchema(base_schema.BaseSchema):
    _schema_name = "vxlanControllers"
    """"""
    def __init__(self, py_dict = None):
        """ Constructor to create VXLANControllers object

        @param py_dict : python dictionary to construct this object
        """
        super(VXLANControllersSchema, self).__init__()
        self.set_data_type('xml')
        self.controller = [controllerSchema()]

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

