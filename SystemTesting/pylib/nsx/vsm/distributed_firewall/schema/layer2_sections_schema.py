import base_schema
from section_schema import SectionSchema

class Layer2SectionsSchema(base_schema.BaseSchema):
    _schema_name = "layer2Sections"

    def __init__(self, py_dict=None):
        """ Constructor to create Layer2SectionsSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(Layer2SectionsSchema, self).__init__()
        self.set_data_type("xml")
        self.section = [SectionSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
