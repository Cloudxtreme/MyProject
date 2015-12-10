import subprocess
import time

import vmware.common as common
import vmware.common.global_config as global_config
import vmware.interfaces.service_interface as service_interface

pylogger = global_config.pylogger


class ESX55ServiceImpl(service_interface.ServiceInterface):

    """Command based service related operations"""

    #
    # Test methods
    #

    @classmethod
    def sample_client(cls, client_object,
                      application_type=None,
                      application_id=None,
                      client_type=None,
                      demo_mode=None,
                      expected_output=None,
                      time_delay=0):
        """
        Runs the sample vertical that was written for use on a hypervisor; it
        is a binary tool that is built alongside mpa to test MP+MPA
        communication

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

        # command = 'chmod +x /tmp/sample_client; ' + \
        #           'LD_LIBRARY_PATH=/usr/lib64/vmware/nsx-mpa ' + \
        #           '/tmp/sample_client %s %s %s %s' % \
        #           (application_type, application_id, client_type,
        #           demo_mode)

        if time_delay > 0:
            time.sleep(time_delay)

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

    @classmethod
    def verify_broker_num_clients(cls, client_object, num_clients=None):
        """
        Calls a REST api to verify the number of clients connected to a broker

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type num_clients: integer
        @param num_clients: Indicates number of expected clients
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        mp_ip = client_object.get_broker_ip()

        command = 'curl --noproxy \'*\' -v -u admin:default ' +\
                  '-H "Accept: application/json" ' +\
                  '-H "Content-Type: application/json" ' +\
                  '-k -X GET ' +\
                  'https://%s/api/v1/messaging/clients/' % (mp_ip)
        pylogger.info("%s" % command)
        clients = 0

        try:
            result = subprocess.check_output(command, shell=True,
                                             stderr=subprocess.STDOUT)

            for line in result.splitlines:
                if 'client_token' in line:
                    fields = line.split('\"')
                    uuid = fields[3]
                    pylogger.info("Client-token: %s" % uuid)
                    clients = clients+1

        except Exception, error:
            pylogger.info("Failed to get client-tokens: %s" % error)
            return common.status_codes.FAILURE

        if clients == num_clients:
            return common.status_codes.SUCCESS
        else:
            pylogger.info("No connected clients: %s" % error)
            return common.status_codes.FAILURE

    # TODO: jfieger: the functionality of this method should be moved to keys
    #       once the restapi for the customer endpoint is available
    # TODO: mihaid: api vs cmd? Is service the right interface?
    @classmethod
    def fetch_endpoint_testrpc(cls, client_object, master=True, pre_sleep=0):
        """
        calls a REST api to trigger an rpc call that originates from a broker
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