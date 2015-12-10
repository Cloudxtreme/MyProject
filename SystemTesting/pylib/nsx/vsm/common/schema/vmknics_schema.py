import base_schema
from vdnVmknic_schema import VdnVmknicSchema

class VmknicsSchema(base_schema.BaseSchema):
    _schema_name = "vmknics"
    def __init__(self, py_dict=None):
        """ Constructor to create VmknicsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VmknicsSchema, self).__init__()
        self.vmknics =  [VdnVmknicSchema()]

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
