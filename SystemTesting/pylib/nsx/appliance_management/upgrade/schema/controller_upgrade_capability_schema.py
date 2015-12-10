import base_schema

class ControllerUpgradeCapabilitySchema(base_schema.BaseSchema):
    _schema_name = "controllerClusterUpgradeAvailability"

    def __init__(self, py_dict=None):
        """ Constructor to create ControllerUpgradeCapabilitySchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ControllerUpgradeCapabilitySchema, self).__init__()
        self.set_data_type('xml')
        self.upgradeAvailable = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
