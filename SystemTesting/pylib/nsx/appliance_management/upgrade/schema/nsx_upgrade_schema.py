import base_schema
from nsx_pre_upgrade_question_answer_schema import  NSXPreUpgradeQuestionAnswerSchema

class NSXUpgradeSchema(base_schema.BaseSchema):
    _schema_name = "preUpgradeQuestionsAnswers"

    def __init__(self, py_dict=None):
        """ Constructor to create NSXUpgradeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXUpgradeSchema, self).__init__()
        self.set_data_type('xml')
        self.preUpgradeQuestionsAnswerArray = []

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
