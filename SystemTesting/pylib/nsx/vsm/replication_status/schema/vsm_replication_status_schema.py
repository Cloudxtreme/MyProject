import base_schema
from nsx_manager_status_schema import NSXManagerStatusSchema


class ReplicationStatusSchema(base_schema.BaseSchema):
    _schema_name = "replicationStatus"

    def __init__(self, py_dict=None):
        """ Constructor to create IPSet object

        @param py_dict : python dictionary to construct this object
        """
        super(ReplicationStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.lastClusterSyncTime = None
        self.syncState = None
        self.nsxManagersStatusList = [NSXManagerStatusSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

