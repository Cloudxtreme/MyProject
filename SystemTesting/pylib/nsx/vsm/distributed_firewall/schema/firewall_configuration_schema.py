import base_schema
from layer3_sections_schema import Layer3SectionsSchema
from layer2_sections_schema import Layer2SectionsSchema
from layer3_redirect_sections_schema import Layer3RedirectSectionsSchema

class FirewallConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "firewallConfiguration"

    def __init__(self, py_dict=None):
        """ Constructor to create FirewallConfigurationSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(FirewallConfigurationSchema, self).__init__()
        self.set_data_type("xml")
        self.contextId = None
        self._tag_timestamp = None
        self.layer2Sections = Layer2SectionsSchema()
        self.layer3Sections = Layer3SectionsSchema()
        self.layer3RedirectSections = Layer3RedirectSectionsSchema()
        self.generationNumber = None
        self._objectIsNone = False

        if not py_dict:
            self._objectIsNone = True

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
