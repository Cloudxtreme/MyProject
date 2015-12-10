import base_schema
from interface_schema import InterfaceSchema


class InterfacesSchema(base_schema.BaseSchema):
    _schema_name = "interfaces"
    def __init__(self, py_dict=None):
        """ Constructor to create InterfacesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(InterfacesSchema, self).__init__()
        self.interfaces = [InterfaceSchema()]
        self.set_data_type("xml")

        if py_dict != None:
           self.get_object_from_py_dict(py_dict)
