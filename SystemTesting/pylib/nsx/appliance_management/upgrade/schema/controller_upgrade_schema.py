import base_schema

class ControllerUpgradeSchema(base_schema.BaseSchema):
    _schema_name = "controllerClusterUpgradeStatus"

    def __init__(self, py_dict=None):
        """ Constructor to create ControllerUpgradeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ControllerUpgradeSchema, self).__init__()
        self.set_data_type('xml')
        self.status = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
