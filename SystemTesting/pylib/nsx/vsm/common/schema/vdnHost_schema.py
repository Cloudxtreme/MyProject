import base_schema
from host_schema import HostSchema
from status_schema import StatusSchema
from vmknics_schema import VmknicsSchema

class VdnHostSchema(base_schema.BaseSchema):
    _schema_name = "vdnHost"
    def __init__(self, py_dict=None):
        """ Constructor to create VdnHostSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VdnHostSchema, self).__init__()
        self.host = HostSchema()
        self.status = StatusSchema()
        self.vmknics = VmknicsSchema()

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
