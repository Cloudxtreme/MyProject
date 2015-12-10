import vmware.common.global_config as global_config
import vmware.common as common
import vmware.common.errors as errors
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx.manager.manager_client as manager_client

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    _attribute_map = {
        'id_': 'id',
    }

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):

        if (schema['username'] is None or
            schema['manager_ip'] is None or
            schema['password'] is None or
                schema['manager_thumbprint'] is None):
            raise ValueError("Required parameters not provided.")

        manager_ip = schema['manager_ip']
        username = schema['username']
        password = schema['password']
        thumbprint = schema['manager_thumbprint']

        mgr_obj = manager_client.NSXManagerFacade(ip=manager_ip,
                                                  username=username,
                                                  password=password)
        id_ = mgr_obj.get_node_id()

        # Construct the command arguments
        endpoint = ("join management-cluster " + manager_ip + " "
                    + username + " " + thumbprint + " " + password)
        expect_prompt = ['bytes*', '#']
        pylogger.debug("CLI for join node to mgmt-cluster:[%s]" % endpoint)
        client_obj.connection.request("configure terminal", expect_prompt)

        raw_payload = (client_obj.connection.request(endpoint, expect_prompt)
                       .response_data)

        result_dict = dict()
        lines = raw_payload.strip().splitlines()
        client_obj.connection.close()

        if ((len(lines) > 1) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[1].upper().find("ERROR") > 0))):
            pylogger.exception("ERROR:Failure observed while running CLI "
                               ": %s" % raw_payload)
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason='join management-cluster command '
                                         'execution returned error')
        else:
            result_dict['id_'] = id_
            return result_dict

    @classmethod
    def delete(cls, client_obj, manager_ip=None):

        # No join management cluster node
        endpoint = "no management-cluster node"
        expect_prompt = ['bytes *', '#']

        if manager_ip is None:
            raise ValueError("Received empty manager ip")

        endpoint = endpoint + " " + manager_ip

        pylogger.debug("CLI to remove node from mgmt-cluster:[%s]" % endpoint)
        client_obj.connection.request("configure terminal", expect_prompt)

        raw_payload = (client_obj.connection.request(endpoint, expect_prompt)
                       .response_data)

        result_dict = dict()
        lines = raw_payload.strip().splitlines()
        client_obj.connection.close()

        if ((len(lines) > 1) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[1].upper().find("ERROR") > 0))):
            pylogger.exception("ERROR:Failure observed while running CLI: %s"
                               % raw_payload)
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason='no join management-cluster command '
                                         'execution returned error')
        else:
            result_dict['response_data']['status_code'] = (common.status_codes
                                                           .SUCCESS)
            return result_dict
