import base_schema
from vsm_vnic_schema import VnicSchema

class VnicsSchema(base_schema.BaseSchema):
    _schema_name = "vnics"
    def __init__(self, py_dict=None):
        """ Constructor to create VnicsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VnicsSchema, self).__init__()
        self.vnics = []
        self.set_data_type("xml")

        if py_dict != None:
            if 'vnics' in py_dict:
                for vnic in py_dict['vnics']:
                    self.vnics.append(VnicSchema(vnic))
        else:
            self.vnics = [VnicSchema()]
