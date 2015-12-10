import base_schema
#import inspect

class ServiceImplementationSchema(base_schema.BaseSchema):
    _schema_name = "implementation"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceImplementationSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceImplementationSchema, self).__init__()
        self.set_data_type('xml')
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)