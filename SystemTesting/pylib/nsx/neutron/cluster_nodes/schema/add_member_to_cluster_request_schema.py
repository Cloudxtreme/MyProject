import base_schema

class AddMemberToClusterRequest(base_schema.BaseSchema):
    _schema_name = "addmembertoclusterrequest"

    def __init__(self, py_dict=None):

        super(AddMemberToClusterRequest, self).__init__()
        self.password = None
        self.user_name = None
        self.remote_address = None
        self.cert_thumbprint = None
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
