from appliance_schema import ApplianceSchema
import base_schema


class AppliancesSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "appliances"
    def __init__(self, py_dict=None):
        """ Constructor to create AppliancesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(AppliancesSchema, self).__init__()
        self.set_data_type("xml")
        self.applianceSize = None
        self.deployAppliances = None
        self.appliance = [ApplianceSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)