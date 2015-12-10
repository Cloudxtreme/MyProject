import base_schema


class LoadBalancerPersistenceSchema(base_schema.BaseSchema):
    _schema_name = "persistence"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerPersistenceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerPersistenceSchema, self).__init__()
        self.set_data_type('xml')
        self.method = None
        self.cookieName = None
        self.cookieMode = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)