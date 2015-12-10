import base_schema
from vsm_ipset_schema import IPSetSchema

class IPSetsSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "list"
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPSetsSchema, self).__init__()
        self.list = [IPSetSchema()]
        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
