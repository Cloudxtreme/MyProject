import base_schema

class DistributedVirtualPortGroupsSchema(base_schema.BaseSchema):
    _schema_name = "distributedVirtualPortGroups"

    def __init__(self, py_dict=None):
        """ Constructor to create DistributedVirtualPortGroupsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DistributedVirtualPortGroupsSchema, self).__init__()
        self.set_data_type('xml')
        self.string = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)