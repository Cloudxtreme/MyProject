import json
import xmlrpclib

import vmware.common.global_config as global_config
import vmware.common as common
import vmware.linux.cmd.linux_messaging_impl as linux_messaging_impl

pylogger = global_config.pylogger


class ESX55MessagingImpl(linux_messaging_impl.LinuxMessagingImpl):

    """Command based messaging related operations"""

    # TODO - mihaid - Enhance vmware.linux.linux_helper.create_file to write to
    # files and use here

    @classmethod
    def _setup_python_sample_client(cls, client_object):
        '''
        Copy sample client to proper directory and untar

        Commands:

        cp (sample client location)sample_client_python.tar.gz
                  /usr/lib/vmware/nsx-common/lib/python/;
        cd /usr/lib/vmware/nsx-common/lib/python/ ;
        untar sample_client_in_python.tar;
        mv sample_client_in_python/*.*  ./
        '''

        # TODO - Add untar as a helper

        protobuf_dir = '/usr/lib/vmware/nsx-common/lib/python/'
        untar_sclient_cmd = 'tar -zxvf %s/sample_client_python.tar.gz' % \
            protobuf_dir
        copy_client = 'cp %s/sample_client_python.tar.gz %s' % \
            (global_config.SAMPLE_CLIENT_LOCATION, protobuf_dir)

        cmd = '%s; cd %s ; %s ; mv sample_client_in_python/* ./' % \
            (copy_client, protobuf_dir, untar_sclient_cmd)
        pylogger.debug(cmd)

        try:
            result = client_object.connection.request(cmd, strict=False)
            pylogger.info("setting up sample client; response: %s" %
                          result.response_data)
        except Exception as error:
            pylogger.error("failed to setup sample client: %s" % error)
            raise

    @classmethod
    def _run_sample_client(cls, client_object):
        '''
        Run the python sample client as a background process

        Commands:

        nohup python /usr/lib/vmware/nsx-common/lib/python/sample_client.py
        /usr/lib/vmware/nsx-mpa/librmqclient.so < /dev/null >
        foo.log 2>&1 &)
        '''

        protobuf_dir = '/usr/lib/vmware/nsx-common/lib/python/'
        sample_client_py = '%s/sample_client.py' % protobuf_dir
        run_client = 'nohup python %s %s' % \
            (sample_client_py, global_config.DEFAULT_ESX_RMQLIB_PATH)
        cmd = "%s < /dev/null > foo.log 2>&1 &" % run_client
        pylogger.debug(cmd)
        try:
            result = client_object.connection.request(cmd, strict=False)
            pylogger.info("run sample_client response: %s",
                          result.response_data)
        except Exception as error:
            pylogger.error("failed to run sample client: %s" % error)
            raise

    @classmethod
    def _configure_sample_client_xmlrpc(cls, client_object):
        '''
        Wrapper for properly configuring the xmlrpc sample client
        '''
        try:
            cls._setup_python_sample_client(client_object)
            cls._run_sample_client(client_object)

        except Exception as error:
            pylogger.error("failed to configure sample client: %s" % error)
            raise

    @classmethod
    def connect_sample_client(cls, client_object, host_ip=None, name=None):
        """
        Connect a type of sample client

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type host_ip: ip address
        @param host_ip: Host to attempt sample client conenction on
        @type name: string
        @param name: Type of sample client used
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        if name == 'xmlrpc':
            return cls._configure_sample_client_xmlrpc(client_object)
        else:
            pylogger.error("Connection type not supported: %s", name)
            return common.status_codes.FAILURE

    @classmethod
    def vertical_registration(cls, client_object, host_ip=None,
                              application_type=None, application_id=None,
                              client_type=None, registration_options=None,
                              vertical_registration=None):
        """
        Registers sample client vertical to a broker

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type host_ip: ip address
        @param host_ip: Host to open connection on
        @type application_type: string
        @param application_type: RMQ Header: appType
        @type application_id: string
        @param application_id: RMQ Header: appID
        @type client_type: string
        @param client_type: RMQ Header: client_type
        @type registration_options: string
        @param registration_options: Optional parameters during registration
        @rtype: dict
        @return: {cookie_id:<value>}
        """
        _ = vertical_registration
        server_url = 'http://%s:8000' % str(host_ip[0])
        pylogger.info("Registering vertical on %s" % host_ip[0])
        s = xmlrpclib.Server(server_url, allow_none=True)
        pylogger.debug("xmlrpc_server is connected%s" % s)

        s.create_rmqMessageLoop()
        s.call_rmqClient_NETEventLoop()

        headers = {"appType": application_type,
                   "appID": application_id,
                   "client_type": int(client_type)}
        if registration_options:
            registration_options = json.loads(registration_options)
            headers.update(registration_options)
            pylogger.debug("The Registration Options: %s",
                           registration_options)

        pylogger.debug("Message headers: %s", headers)

        cookieid = s.test_rmqClient_InitNETClient(headers)
        pylogger.debug("cookiedID is %s" % str(cookieid))
        pylogger.debug("Vertical registration completed")
        return_dict = {'cookie_id': cookieid}
        return return_dict

    @classmethod
    def vertical_close_connection(cls, client_object, host_ip=None,
                                  cookieid=None):
        """
        Closes the sample client vertical's connection and deletes cookiedID
        file

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type host_ip: ip address
        @param host_ip: Host to close connection on
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """

        server_url = 'http://%s:8000' % str(host_ip[0])
        pylogger.info("Closing connection on %s" % host_ip[0])
        s = xmlrpclib.Server(server_url, allow_none=True)
        pylogger.debug("xmlrpc_server is connected%s" % s)

        if cookieid > 0:
            pylogger.debug("cookiedID is %s" % str(cookieid))
            s.test_close_client_connection(cookieid)
            pylogger.debug("Close client succeeded")
            return common.status_codes.SUCCESS
        else:
            pylogger.error("cookieid is less than or equal to 0")
            raise ValueError("cookieid is less than or equal to 0")

    @classmethod
    def vertical_send_msg(cls, client_object, host_ip=None, msg_type=None,
                          cookie_id=None, test_params=None,
                          count=None):
        """
        Send generic/rpc/publish message from Host(sample client)
        to MP through MPA

        @type client_object: BaseClient
        @param client_object: Used to send messages from the sample client
        @type host_ip: string
        @param host_ip: IP address of the host
        @type msg_type: int
        @param msg_type: Type of message to be sent
        @type cookie_id: integer
        @param cookie_id: cookie_id from vertical registration
        @type test_params: string/dict
        @param test_params: dictionary containing parameters for messages
        @type count: integer
        @param  count: Number of messages to be sent
        """

        server_url = 'http://%s:8000' % str(host_ip[0])
        xmlrpc_server = xmlrpclib.Server(server_url, allow_none=True)
        pylogger.debug("xmlrpc_server is connected: %s" % xmlrpc_server)
        if cookie_id > 0:
            pylogger.debug("cookiedID is %s" % cookie_id)
            test_param = json.loads(test_params)
            pylogger.debug("Test Parameters are %s" % test_param)

        msg_type_action = {global_config.MSG_TYPE_GENERIC:
                           xmlrpc_server.test_send_generic_message,
                           global_config.MSG_TYPE_RPC:
                           xmlrpc_server.test_vertical_send_rpc,
                           global_config.MSG_TYPE_PUBLISH:
                           xmlrpc_server.test_publish_message}

        msg_type_string = {global_config.MSG_TYPE_GENERIC: 'generic',
                           global_config.MSG_TYPE_RPC: 'rpc',
                           global_config.MSG_TYPE_PUBLISH: 'publish'}
        # send #count messages
        for message in xrange(0, count):
            ret = msg_type_action[msg_type](cookie_id, test_param)
            if ret < 0:
                pylogger.error("Failed to send message [ret :%r, "
                               "msg_type: %r, cookieID: %r,"
                               "test_param: %r]" %
                               (ret, msg_type_string[msg_type], cookie_id,
                                test_param))
                return common.status_codes.FAILURE
            pylogger.debug("Successfully sent message [ret :%s"
                           "msg_type: %r, cookieID: %r, test_param: %r]" %
                           (ret, msg_type_string[msg_type], cookie_id,
                            test_param))
        return common.status_codes.SUCCESS
