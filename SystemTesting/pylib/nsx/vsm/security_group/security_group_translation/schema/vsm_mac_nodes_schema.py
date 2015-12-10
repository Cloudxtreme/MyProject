import base_schema
from vsm_mac_node_schema import MACNodeSchema

class MACNodesSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "macNodes"
    def __init__(self, py_dict=None):
        """ Constructor to create MACNodesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(MACNodesSchema, self).__init__()
        self.set_data_type('xml')
        self.macNode = [MACNodeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)



