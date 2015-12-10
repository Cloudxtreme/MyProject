import base_schema
from vsm_entity_sync_element_schema import VSMEntitySyncElementSchema


class VSMEntitySyncElementsSchema(base_schema.BaseSchema):
    _schema_name = "elements"

    def __init__(self, py_dict=None):
        """ Constructor to replication status for an entity

        @param py_dict : python dictionary to construct this object
        """
        super(VSMEntitySyncElementsSchema, self).__init__()
        self.set_data_type('xml')
        self.entitySyncElement = [VSMEntitySyncElementSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

