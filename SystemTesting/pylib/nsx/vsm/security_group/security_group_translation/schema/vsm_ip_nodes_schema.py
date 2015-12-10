import base_schema
from vsm_ip_node_schema import IPNodeSchema

class IPNodesSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "ipNodes"
    def __init__(self, py_dict=None):
        """ Constructor to create IPNodesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPNodesSchema, self).__init__()
        self.set_data_type('xml')
        self.ipNode = [IPNodeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


