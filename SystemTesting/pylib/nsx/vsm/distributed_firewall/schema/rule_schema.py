import base_schema
from sources_schema import SourcesSchema
from services_schema import ServicesSchema
from applied_to_list_schema import AppliedToListSchema
from destinations_schema import DestinationsSchema
from si_profile_schema import SiProfileSchema

class RuleSchema(base_schema.BaseSchema):
    _schema_name = "rule"

    def __init__(self, py_dict=None):
        """ Constructor to create RuleSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RuleSchema, self).__init__()
        self.set_data_type("xml")
        self.name = None
        self.sectionId = None
        self.notes = None
        self.sources = SourcesSchema()
        self.services = ServicesSchema()
        self.action = None
        self.appliedToList = AppliedToListSchema()
        self.destinations = DestinationsSchema()
        self.precedence = None
        self.siProfile = SiProfileSchema()
        self._tag_disabled = None
        self._tag_logged = None
        self._tag_id = None
        self._tag_managedBy = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
