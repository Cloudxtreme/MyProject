import json
import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.os_interface as os_interface

pylogger = global_config.pylogger


class ESX55OSImpl(os_interface.OSInterface):

    @classmethod
    def get_tcp_connection_count(cls, client_object, ip_address=None,
                                 port=None, connection_states=None,
                                 keywords=None, **kwargs):
        """
        Returns the tcp connection count using netstat command matching the
        given parameters.

        @type ip_address: string
        @param ip_address: Check connection to this IP address.
        @type port: integer
        @param port: Check connection state to this port number.
        @type connection_states: list
        @param connection_states: Any list of states from
            constants.TCPConnectionState.STATES.
        @type keywords: list
        @param keywords: List of keywords to grep.
        @rtype: dictionary
        @return: {'result_count': <Number of matching connections>}
        """
        for state in connection_states:
            if state not in constants.TCPConnectionState.STATES:
                raise ValueError("Expected connection state not defined: %s" %
                                 state)
        ip_address = ip_address or ''
        port = port or ''
        cmd = 'esxcli network ip connection list | grep %s:%s' % (ip_address,
                                                                  port)
        if keywords:
            cmd = "%s | grep %s" % (cmd, " | grep ".join(keywords))
        cmd = "%s | grep -c -e %s" % (cmd, " -e ".join(connection_states))
        result = client_object.connection.request(cmd, strict=False)
        return {'result_count': int(result.response_data.rstrip())}

    @classmethod
    def set_hostname(cls, client_object, hostname, set_hostname=None):
        """
        Method to set hostname of esx host.

        @type hostname: str
        @param hostname: hostname to be modify
        @rtype: status code
        @return: command status
        """
        _ = set_hostname

        command = 'esxcli system hostname set -f ' + hostname
        try:
            client_object.connection.request(command, ['bytes*', '#'])
        except Exception:
            error_msg = (
                "Command [%s] threw an exception during execution" % command)
            pylogger.exception(error_msg)
            raise errors.CLIError(status_code=common.status_codes.FAILURE)
        finally:
            client_object.connection.close()

        return common.status_codes.SUCCESS

    @classmethod
    def read_hostname(cls, client_object, read_hostname=None):
        """
        Method to return hostname of esx host.

        @rtype: dict
        @return: dictionary having esx hostname
        """
        _ = read_hostname

        command = 'esxcli --debug --formatter=json system hostname get'

        try:
            raw_payload = client_object.connection.request(
                command, ['bytes*', '#']).response_data
        except Exception:
            error_msg = (
                "Command [%s] threw an exception during execution" % command)
            pylogger.exception(error_msg)
            raise errors.CLIError(status_code=common.status_codes.FAILURE)
        finally:
            client_object.connection.close()

        ###
        # Command returns json format string e.g.
        #   {"DomainName": "eng.vmware.com",
        #    "FullyQualifiedDomainName": "colo-nimbus-dhcp.eng.vmware.com",
        #    "HostName": "colo-nimbus-dhcp"}
        # Converting this string to dictionary using json module
        ###
        pydict = json.loads(raw_payload)
        return {"hostname": pydict["FullyQualifiedDomainName"]}
