import base_schema


class MACLearningConfigSchema(base_schema.BaseSchema):
    _schema_name = "macLearningConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create MacLearningConfig object

        @param py_dict : python dictionary to construct this object
        """
        super(MACLearningConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
