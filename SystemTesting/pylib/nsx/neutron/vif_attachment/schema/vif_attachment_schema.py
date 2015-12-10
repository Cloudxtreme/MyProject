import base_schema
from resource_link_schema import ResourceLinkSchema

class VifAttachmentSchema(base_schema.BaseSchema):
    _schema_name = "vifattachment"

    def __init__(self, py_dict=None):
        """ Constructor to create VifAttachment object

        @param py_dict : python dictionary to construct this object
        """
        super(VifAttachmentSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self._create_time = None
        self._links = [ResourceLinkSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None
        self.vif_uuid = None
        self.type = None
        self.peer_id = None
        self._host_type = None
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
