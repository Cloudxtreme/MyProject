import base_schema


class LoadBalancerHttpRedirectSchema(base_schema.BaseSchema):
    _schema_name = "httpRedirect"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerHttpRedirectSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerHttpRedirectSchema, self).__init__()
        self.set_data_type('xml')
        self.to = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)