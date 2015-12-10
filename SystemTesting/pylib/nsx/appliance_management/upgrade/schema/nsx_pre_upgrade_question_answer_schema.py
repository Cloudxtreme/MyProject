import base_schema

class NSXPreUpgradeQuestionAnswerSchema(base_schema.BaseSchema):
    _schema_name = "preUpgradeQuestionAnswer"

    def __init__(self, py_dict=None):
        """ Constructor to create NSXUpgrade question answer schema object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXPreUpgradeQuestionAnswerSchema, self).__init__()
        self.set_data_type('xml')
        self.questionId = None
        self.question = None
        # Product attribute itself has a typo
        self.questionAnserType = None
        self.answer = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
