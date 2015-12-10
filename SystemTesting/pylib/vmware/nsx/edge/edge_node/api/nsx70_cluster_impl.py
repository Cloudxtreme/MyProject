import vmware.common.global_config as global_config
import vmware.nsx_api.manager.edgeclusters.schema.\
    edgeclusterlistresult_schema as edgeclusterlistresult_schema
import vmware.interfaces.cluster_interface as cluster_interface
import vmware.nsx.edge.edge_cluster.api.edge_cluster_api_client as \
    edge_cluster_api_client

pylogger = global_config.pylogger


class NSX70ClusterImpl(cluster_interface.ClusterInterface):

    @classmethod
    def get_member_index(cls, client_obj):
        cluster_object = edge_cluster_api_client.\
            EdgeClusterAPIClient(parent=client_obj.parent)
        result_dict = cluster_object.query()
        pylogger.info("Result of get edge cluster : %s " % result_dict)

        edgeClusterListResultSchemaObject = edgeclusterlistresult_schema.\
            EdgeClusterListResultSchema(result_dict['response'])
        listOfEdgeClusterListResultSchemaObject = edgeClusterListResultSchemaObject.\
            results

        for edgeClusterSchemaObject in \
                listOfEdgeClusterListResultSchemaObject:
            for member in edgeClusterSchemaObject.members:
                if member.edge_node_id == client_obj.id_:
                    return str(member.member_index)
        else:
            raise ValueError("Failed to get the member index for "
                             "edge node id %s" % client_obj.id_)
