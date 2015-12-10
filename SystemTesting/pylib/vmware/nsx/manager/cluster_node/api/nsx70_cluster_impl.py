import vmware.nsx_api.manager.clustermanagement.revokemissingclusternodeconfig as revokeclusternode  # noqa
import vmware.nsx_api.manager.common.revokenoderequest_schema as revokenode_schema  # noqa

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70ClusterImpl(base_crud_impl.BaseCRUDImpl):

    @classmethod
    def revoke_cluster_node(cls, client_object, hosts):
        if hosts is None:
            raise Exception('No node is required to be revoked ..')

        cls._client_class = revokeclusternode.RevokeMissingClusterNodeConfig
        cls._schema_class = revokenode_schema.RevokeNodeRequestSchema

        revoke_client_class_obj = cls._client_class(
            connection_object=client_object.connection)

        payload = {"hosts": hosts}
        revoke_schema_object = cls._schema_class(payload)
        revoke_schema_object = revoke_client_class_obj.\
            create(revoke_schema_object)

        result_dict = {}
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            revoke_client_class_obj.last_calls_status_code)
        return result_dict