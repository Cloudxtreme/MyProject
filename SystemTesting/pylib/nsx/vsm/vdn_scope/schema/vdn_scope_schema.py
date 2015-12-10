import base_schema
from clusters_schema import ClustersSchema


class VDNScopeSchema(base_schema.BaseSchema):
    _schema_name = 'vdnScope'
    def __init__(self, py_dict=None):
        """ Constructor to create VDNScopeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VDNScopeSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.type = None
        self.name = None
        self.description = None
        self.revision = None
        self.objectTypeName = None
        self.extendedAttributes = None
        self.id = None
        self.clusters = ClustersSchema()
        self.virtualWireCount = None
        self.vsmUuid = None
        self.controlPlaneMode = None
        self.isUniversal = None
        self.universalRevision = None

        if py_dict is not None:
            if 'name' in py_dict:
                self.name = py_dict['name']
            if 'controlplanemode' in py_dict:
                self.controlPlaneMode = py_dict['controlplanemode']
            if 'objectid' in py_dict:
                self.objectId = py_dict['objectid']
            if 'clusters' in py_dict:
                self.clusters = ClustersSchema(py_dict['clusters'])


if __name__ == '__main__':
    py_dict = {'name': 'vdn-schema-test', 'clusters': {'cluster': [{'objectId': 'domain-c7'}]}}
    test_obj = VDNScopeSchema(py_dict)
    print "xml %s" % test_obj.get_data('xml')
