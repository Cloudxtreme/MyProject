import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.setup_interface as setup_interface

pylogger = global_config.pylogger


class NSX70SetupImpl(setup_interface.SetupInterface):

    TUNNEL_PREFIX = "/config/moot-server/security/tun_"

    @classmethod
    def clear_controller(cls, client_obj):

        """Clear the left process in ccp"""
        connection = client_obj.connection
        command = 'docker ps -q | xargs docker kill | xargs docker rm'
        result = connection.request(command,
                                    expect=['bytes*', '#'])
        response = result.response_data
        if 'docker' in response:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=response)
        command = "ps ax|grep openvpn-moot|awk '{print $1}'|xargs kill -9"
        result = connection.request(command,
                                    expect=['bytes*', '#'])
        command = 'openvpn-moot --rmtun --dev tun0'
        result = connection.request(command,
                                    expect=['bytes*', '#'])
        return constants.Result.SUCCESS.upper()

    @classmethod
    def tunnel_process(cls, client_obj, endpoints=None,
                       operation=None):
        """
        Kill/Check tunnel to other conntroller on controller

        @type endpoints: List
        @param endpoints: List of controller object, to get ip address
        @type operation: String
        @param operation: kill/check
        """
        connection = client_obj.connection
        status_code = common.status_codes.FAILURE
        command = None
        error_info = 'No such file'
        if operation == 'kill':
            pid_list = []
            for endpoint in endpoints:
                if endpoint.ip != client_obj.ip:
                    filepath = cls.TUNNEL_PREFIX + endpoint.ip + ":7777.pid"
                    command = "cat %s" % filepath
                    result = connection.request(command,
                                                expect=['bytes*', '#'])
                    response = result.response_data
                    if error_info in response:
                        pylogger.error("File %s doesn't exist" % filepath)
                        raise errors.CLIError(status_code=status_code,
                                              reason=response)
                    pid = response.split("\n")[0].strip()
                    pid_list.append(pid)
            pid_list = ' '.join(pid_list)
            pylogger.debug("The pid list should be killed is %s" % pid_list)
            command = "kill %s" % pid_list
            result = connection.request(command,
                                        expect=['bytes*', '#'])
            response = result.response_data
            if 'process' in response:
                raise errors.CLIError(status_code=status_code, reason=response)
        elif operation == 'check':
            for endpoint in endpoints:
                if endpoint.ip != client_obj.ip:
                    filepath = cls.TUNNEL_PREFIX + endpoint.ip
                    command = "cat %s:7777.pid" % filepath
                    result = connection.request(command,
                                                expect=['bytes*', '#'])
                    response = result.response_data
                    if error_info in response:
                        pylogger.error("File %s doesn't exist" % filepath)
                        raise errors.CLIError(status_code=status_code,
                                              reason=response)
                    pid = response
                    command = "ps ax|grep %s|awk '{print $1}'" % filepath
                    result = connection.request(command,
                                                expect=['bytes*', '#'])
                    response = result.response_data
                    if pid not in response:
                        raise errors.CLIError(status_code=status_code,
                                              reason=response)
        else:
            raise ValueError("Received unknown <%s> tunnel "
                             "partitioning operation"
                             % operation)
        return constants.Result.SUCCESS.upper()
