import base_schema
from ptep_entry_schema import PTEPEntrySchema

class PTEPClusterSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "replicationcluster"
    def __init__(self, py_dict=None):
        """ Constructor to create PTEPClusterSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(PTEPClusterSchema, self).__init__()
        self.set_data_type('xml')
        self.hosts = [PTEPEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
