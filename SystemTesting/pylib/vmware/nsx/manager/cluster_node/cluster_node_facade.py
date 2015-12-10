import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels
import vmware.nsx.manager.cluster.api.cluster_api_client as cluster_api_client
import vmware.nsx_api.manager.clustermanagement.readclusterstatus as read_cluster_status  # noqa
import vmware.nsx.manager.cluster_node.cluster_node as cluster_node
import vmware.nsx.manager.cluster_node.api.cluster_node_api_client as cluster_node_api_client  # noqa
import vmware.nsx.manager.cluster_node.cli.cluster_node_cli_client as cluster_node_cli_client  # noqa
import vmware.workarounds as workarounds

pylogger = global_config.pylogger


def _preprocess_resolve_host_address(obj, kwargs):
    """
    Bug #1423136 : This bug is raised on product to
    get FQDN of MP node. For now we have to determine
    hosts from GET /cluster/status. So implemented
    this in preprocess function.

    Determine the hosts that needs to be revoked
    Gets host address from /cluster/status and update
    it in caller's <kwargs>.
    :param obj: the facade interfacing to a specific cluster node
    :param kwargs: Reference to dictionary.
    """
    if not workarounds.nsx_manager_revoke_api_workaround.enabled:
        return
    cluster_obj = cluster_api_client.ClusterAPIClient(
        parent=obj.get_client(execution_type='api'))

    client_class_obj = read_cluster_status.ReadClusterStatus(
        connection_object=cluster_obj.connection)

    status_schema_object = client_class_obj.read()
    status_schema_dict = status_schema_object.get_py_dict_from_object()
    cluster_status_dict = status_schema_dict['mgmt_cluster_status']

    hosts = None
    if 'required_members_for_initialization' in cluster_status_dict:
        if len(cluster_status_dict[
                'required_members_for_initialization']) != 0:
            hosts = []
            for node in cluster_status_dict[
                    'required_members_for_initialization']:
                hosts.append(node['host_address'])

    kwargs.update({'hosts': hosts})


class ClusterNodeFacade(cluster_node.ClusterNode, base_facade.BaseFacade):
    """Cluster Node facade class to perform CRUDAQ"""
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(ClusterNodeFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects.
        api_client = cluster_node_api_client.ClusterNodeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = cluster_node_cli_client.ClusterNodeCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

    @base_facade.auto_resolve(labels.CLUSTER,
                              preprocess=_preprocess_resolve_host_address)
    def revoke_cluster_node(self, execution_type=None, **kwargs):
        pass
