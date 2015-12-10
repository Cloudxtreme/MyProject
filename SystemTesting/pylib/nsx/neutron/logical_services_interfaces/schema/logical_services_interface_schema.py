import base_schema
from resource_link_schema import ResourceLinkSchema
from tag_schema import TagSchema
from interface_options_schema import InterfaceOptionsSchema
from address_group_schema import AddressGroupSchema

class LogicalServicesInterfaceSchema(base_schema.BaseSchema):
    _schema_name = "logicalservicesinterface"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalServicesInterfaceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LogicalServicesInterfaceSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
#        self.tags = [TagSchema()]
        self._create_time = None
        self._links = [ResourceLinkSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None
        self.interface_number = None
        self.interface_type = None
        self.interface_options = InterfaceOptionsSchema()
        self.address_groups = [AddressGroupSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
