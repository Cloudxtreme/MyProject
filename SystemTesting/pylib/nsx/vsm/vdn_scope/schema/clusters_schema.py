import base_schema
from cluster_schema import ClusterSchema
from dummy_cluster_schema import DummyClusterSchema


class ClustersSchema(base_schema.BaseSchema):
    _schema_name = "clusters"
    def __init__(self, py_dict=None):
        """ Constructor to create ScopeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ClustersSchema, self).__init__()
        self.cluster = [ClusterSchema()]

        if py_dict is not None:
            self.cluster = []
            if 'cluster' in py_dict:
               # The code below this needs to removed in future
               for cls in py_dict['cluster']:
                    clusterSchema = DummyClusterSchema(cls)
                    self.cluster.append(clusterSchema)
