import base_schema
from collector_schema import CollectorSchema

class IpfixConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "ipfixConfiguration"

    def __init__(self, py_dict=None):
        """ Constructor to create IpfixConfigurationSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(IpfixConfigurationSchema, self).__init__()
        self.set_data_type("xml")
        self.collector = [CollectorSchema()]
        self.observationDomainId = None
        self.contextId = None
        self.ipfixEnabled = None
        self.flowTimeout = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
