import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.hypervisor_interface as hypervisor_interface


pylogger = global_config.pylogger
NSXCLI_SCRIPT_PATH_ON_HV = '/opt/vmware/nsx-cli/bin/scripts/nsxcli'


class ESX55HypervisorImpl(hypervisor_interface.HypervisorInterface):

    @classmethod
    def get_host_uuid(cls, client_object, get_host_uuid=None):
        """
        Method to execute 'show host uuid' cli on ESX host using nsxcli and
        return the fetched uuid.

        @rtype: dict
        @return: dictionary having host UUID
        """
        _ = get_host_uuid
        # Setting up the pexpect connection
        client_object.set_connection(
            connection_type=constants.ConnectionType.EXPECT)
        connection = client_object.connection

        # Invoking nsxcli prompt where the cli would run
        command = NSXCLI_SCRIPT_PATH_ON_HV
        expect_prompt = ['bytes*', '.>']

        try:
            connection.request(command, expect_prompt)

            endpoint = "show host uuid"
            raw_payload = connection.request(
                endpoint, expect_prompt).response_data
            connection.request(command='exit', expect=['bytes*', '#'])
        except Exception:
            error_msg = \
                "NSXCLI [%s] thrown exception during execution" % endpoint
            pylogger.exception(error_msg)
            raise errors.CLIError(status_code=common.status_codes.FAILURE)
        finally:
            client_object.restore_connection()

        if len(raw_payload.splitlines()) == 3:
            return {'host_uuid': raw_payload.splitlines()[1]}
        else:
            raise errors.CLIError(
                status_code=common.status_codes.FAILURE,
                reason='Unexpected CLI output returned, raw_payload: [%s]'
                       % raw_payload)
