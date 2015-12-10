import base_schema
from data_page_schema import DataPageSchema
from virtual_wire_schema import VirtualWireSchema

class VirtualWiresSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "virtualWires"
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VirtualWiresSchema, self).__init__()
        self.dataPage = DataPageSchema(None, VirtualWireSchema())
        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


