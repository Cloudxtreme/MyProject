import base_schema

class ServiceInstanceClustersSchema(base_schema.BaseSchema):
    _schema_name = "clusters"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstanceClustersSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceClustersSchema, self).__init__()
        self.set_data_type('xml')
        self.string = [str()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
