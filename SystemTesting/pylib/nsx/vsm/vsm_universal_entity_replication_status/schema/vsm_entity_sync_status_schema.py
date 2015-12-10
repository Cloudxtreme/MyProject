import base_schema
from vsm_entity_sync_element_schema import VSMEntitySyncElementSchema


class VSMEntitySyncStatusSchema(base_schema.BaseSchema):
    _schema_name = "replicationStatus"

    def __init__(self, py_dict=None):
        """ Constructor to get replication status for an entity

        @param py_dict : python dictionary to construct this object
        """
        super(VSMEntitySyncStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.objectType = None
        self.isInSync = None
        self.elements = [VSMEntitySyncElementSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

