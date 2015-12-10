import base_schema
from vdnHost_schema import VdnHostSchema

class ListSchema(base_schema.BaseSchema):
    _schema_name = "list"
    def __init__(self, py_dict=None,list_object=None):
        """ Constructor to create ListSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ListSchema, self).__init__()
        self.list_object = [list_object()]

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
