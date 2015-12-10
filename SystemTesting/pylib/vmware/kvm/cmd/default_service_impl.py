import subprocess
import time
import vmware.common as common
import vmware.common.global_config as global_config
import vmware.linux.cmd.linux_service_impl as linux_service_impl

pylogger = global_config.pylogger


class DefaultServiceImpl(linux_service_impl.LinuxServiceImpl):
    """Command based service related operations"""

    @classmethod
    def sample_client(cls, client_object,
                      application_type=None,
                      application_id=None,
                      client_type=None,
                      demo_mode=None,
                      expected_output=None,
                      time_delay=0):
        """
        sample_client method runs the sample vertical that was written for
        use on a hypervisor; it is a binary tool that is built alongside mpa
        to test MP+MPA communication

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type application_type: string
        @param application_type: a vertical specific string. unique within nsx
        @type application_id: string
        @param application_id: not used. can be any string
        @type client_type: integer
        @param client_type: 1, net-type, only supported type for now
        @type demo_mode: integer
        @param demo_mode: 0=interactive, 1=generic, 2=rpc, 3=publish
        @type expected_output: string
        @param expected_output: a string from the stdout of sample client
        @type time_delay: integer
        @param time_delay: seconds prior to starting sample client, def: 0
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """

        # rmqclient_sample <appType> <appId> <client type> <demo mode>
        command = global_config.DEFAULT_SAMPLE_CLIENT_START_SEQUENCE + \
            " %s %s %s %s &" % \
            (application_type, application_id, client_type, demo_mode)

        if time_delay > 0:
            time.sleep(time_delay)

        pylogger.info("Starting sample client with command: %s" % command)

        pylogger.debug("%s" % command)

        result = None
        try:
            result = client_object.connection.request(command, strict=False)
            pylogger.info("%s" % result.response_data)
        except Exception, error:
            pylogger.error("Sample client failed to run: %s" % error)
            raise ValueError("Sample client failed to run: %s" % error)

        if expected_output in result.response_data:
            pylogger.info("Sample client output looks good")
            return common.status_codes.SUCCESS
        else:
            pylogger.error("Did not find string: %s" % expected_output)
            raise ValueError('Sample client expected output not found')

    # TODO: jfieger: the functionality of this method should be moved to keys
    #       once the restapi for the customer endpoint is available
    @classmethod
    def fetch_endpoint_testrpc(cls, client_object, master=True, pre_sleep=0):
        """
        Calls a REST api to trigger an rpc call that originates from a broker
        to a client

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type master: boolean
        @param master: Indicates whether the call originates from master or not
        @type pre_sleep: integer
        @param pre_sleep: Amount of time to sleep before method (seconds)
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        mp_ip = client_object.get_broker_ip()

        uuid = client_object.get_client_token()

        if master is False:
            mp_ip = client_object.get_broker_ip(num=1)

        # Use the client-token to get a broker to call an RPC on it

        command = 'curl --noproxy \'*\' -v -u admin:default ' +\
                  '-H "Accept: application/json" ' +\
                  '-H "Content-Type: application/json" ' +\
                  '-k -X POST ' +\
                  'https://%s/api/v1/customer/host-clients/%s/testrpc' % \
                  (mp_ip, uuid)

        # at this point we need to sleep as sample_client will be
        # started in another thread (at the key scope)
        pylogger.debug("Sleeping 3 seconds to allow client to respond")
        time.sleep(3)

        try:
            result = subprocess.check_output(command, shell=True,
                                             stderr=subprocess.STDOUT)

            http_status_line = 'unknown'
            for line in result.split('\n'):
                if 'HTTP/1.1' in line:
                    http_status_line = line

            # I expect this in the output:
            #      HTTP/1.1 201 Created
            #      TODO: Check for "Customer Vertical RPC response for MP"
            if 'HTTP/1.1 201 Created' in http_status_line:
                pylogger.debug(http_status_line)
                return common.status_codes.SUCCESS
            else:
                pylogger.error(http_status_line)
                return common.status_codes.FAILURE

        except Exception, error:
            pylogger.info("Failed to run testrpc: %s" % error)
            return common.status_codes.FAILURE
