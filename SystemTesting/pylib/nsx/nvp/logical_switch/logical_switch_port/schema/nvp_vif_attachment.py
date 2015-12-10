import base_schema

class VIFAttachmentSchema(base_schema.BaseSchema):
    _schema_name = "vifattachment"

    def __init__(self, py_dict=None):
        """ Constructor to create vifattachment object

        @param py_dict : python dictionary to construct this object
        """
        super(VIFAttachmentSchema, self).__init__()
        self.type = 'VifAttachment'
        self.vif_uuid = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
