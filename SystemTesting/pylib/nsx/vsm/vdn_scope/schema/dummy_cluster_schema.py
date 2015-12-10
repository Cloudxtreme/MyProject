import base_schema
from cluster_schema import ClusterSchema


class DummyClusterSchema(base_schema.BaseSchema):
    _schema_name = "cluster"
    def __init__(self, py_dict=None):
        """ Constructor to create DummyClusterSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DummyClusterSchema, self).__init__()
        self.cluster = []

        if py_dict is not None:
            if 'cluster' in py_dict:
               clusterSchema = ClusterSchema(py_dict['cluster'])
               self.cluster.append(clusterSchema)

