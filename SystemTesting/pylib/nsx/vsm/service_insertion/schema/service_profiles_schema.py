import base_schema
from service_profile_schema import ServiceProfileSchema

class ServiceProfilesSchema(base_schema.BaseSchema):
    _schema_name = "serviceProfiles"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceProfilesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceProfilesSchema, self).__init__()
        self.set_data_type('xml')
        self.serviceProfileArray = [ServiceProfileSchema()]
        self._getserviceprofileflag = None
        self._serviceprofilename = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
