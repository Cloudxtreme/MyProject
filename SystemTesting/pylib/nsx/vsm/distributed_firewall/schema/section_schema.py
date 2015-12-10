import base_schema
from rule_schema import RuleSchema

class SectionSchema(base_schema.BaseSchema):
    _schema_name = "section"

    def __init__(self, py_dict=None):
        """ Constructor to create SectionSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(SectionSchema, self).__init__()
        self.set_data_type("xml")
        self.rule = [RuleSchema()]
        self._tag_id = None
        self._tag_name = None
        self._tag_generationNumber = None
        self._tag_timestamp = None
        self._tag_type = None
        self._tag_managedBy = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
