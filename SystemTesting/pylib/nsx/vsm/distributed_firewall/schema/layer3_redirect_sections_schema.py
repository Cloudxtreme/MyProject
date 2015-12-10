import base_schema
from section_schema import SectionSchema

class Layer3RedirectSectionsSchema(base_schema.BaseSchema):
    _schema_name = "layer3RedirectSections"

    def __init__(self, py_dict=None):
        """ Constructor to create Layer3RedirectSectionsSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(Layer3RedirectSectionsSchema, self).__init__()
        self.set_data_type("xml")
        self.section = [SectionSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
