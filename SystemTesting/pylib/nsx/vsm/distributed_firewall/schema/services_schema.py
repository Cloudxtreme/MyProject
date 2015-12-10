import base_schema
from df_service_schema import ServiceSchema

class ServicesSchema(base_schema.BaseSchema):
    _schema_name = "services"

    def __init__(self, py_dict=None):
        """ Constructor to create ServicesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServicesSchema, self).__init__()
        self.set_data_type("xml")
        self.service = [ServiceSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
