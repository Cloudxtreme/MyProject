import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.readnodestatus as readnodestatus
import vmware.nsx_api.appliance.node.restartorshutdownnode \
    as restartorshutdownnode
import vmware.nsx_api.appliance.node.schema.nodeproperties_schema\
    as nodeproperties_schema
import vmware.nsx.manager.cluster_node.api.cluster_node_api_client as cluster_node_api_client  # noqa
import vmware.nsx.manager.cluster.api.cluster_api_client as cluster_api_client


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = restartorshutdownnode.RestartOrShutdownNode
    _schema_class = nodeproperties_schema.NodePropertiesSchema

    @classmethod
    def update(cls, client_obj, **kwargs):
        schema = kwargs
        kwargs = {'merge': 'false'}
        return super(NSX70CRUDImpl, cls).update(client_obj,
                                                schema=schema, **kwargs)

    @classmethod
    def get_status(cls, client_obj, **kwargs):
        client_class_obj = readnodestatus.ReadNodeStatus(
            connection_object=client_obj.connection)
        status_schema_object = client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        result_dict = dict()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def get_node_id(cls, client_obj, **kwargs):
        cluster_object = cluster_api_client.ClusterAPIClient(parent=client_obj)
        cluster_object.wait_for_required_cluster_status(
            required_status="STABLE", time_to_monitor=600)
        cluster_node_object = cluster_node_api_client.ClusterNodeAPIClient(
            parent=client_obj)
        # TODO(Ashutosh): Need error handling
        result_dict = cluster_node_object.query()
        for result in result_dict["response"]["results"]:
            r = result["manager_role"]["mgmt_plane_listen_addr"]["ip_address"]
            if r == client_obj.ip:
                return result["id_"]

    @classmethod
    def get_base_url(cls, client_obj, **kwargs):
        url_format = "https://%s"
        return url_format % client_obj.ip
