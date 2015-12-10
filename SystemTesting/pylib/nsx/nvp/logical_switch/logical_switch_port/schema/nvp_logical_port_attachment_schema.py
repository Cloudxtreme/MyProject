import base_schema
from nvp_vif_attachment import VIFAttachmentSchema
class LogicalPortAttachmentSchema(base_schema.BaseSchema):
    _schema_name = "logicalportattachment"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalPortAttachmentSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LogicalPortAttachmentSchema, self).__init__()

        if 'type' in py_dict:
            if py_dict['type'] == 'vifattachment':
               self = VIFAttachmentSchema(py_dict)
