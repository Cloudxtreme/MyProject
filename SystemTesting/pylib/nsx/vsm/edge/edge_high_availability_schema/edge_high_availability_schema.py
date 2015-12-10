import base_schema
from logging_schema import LoggingSchema
from edge_high_availability_security_schema import HighAvailabilitySecuritySchema
from edge_high_availability_ipaddresses_schema import HighAvailabilityIPAddressesSchema


class HighAvailabilitySchema(base_schema.BaseSchema):
    _schema_name = "highAvailability"
    def __init__(self, py_dict=None):
        """ Constructor to create HighAvailabilitySchema object

        @param py_dict : python dictionary to construct this object
        """
        super(HighAvailabilitySchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.declareDeadTime = None
        self.vnic = None
        self.logging = LoggingSchema()
        self.security = HighAvailabilitySecuritySchema()
        self.ipAddresses = \
            HighAvailabilityIPAddressesSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)