import os
import time
import re
import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.appliance_interface as appliance_interface
import vmware.schema.clock_schema as clock_schema
import vmware.schema.manager.dir_schema as dir_schema
import vmware.schema.manager.show_arp_schema as show_arp_schema
import vmware.schema.manager.show_ip_sockets_schema as show_ip_sockets_schema
import vmware.schema.manager.show_process_monitor_schema \
    as show_process_monitor_schema
import vmware.schema.manager.show_ntp_associations_schema\
    as show_ntp_associations_schema

pylogger = global_config.pylogger


class NSX70ApplianceImpl(appliance_interface.ApplianceInterface):
    @classmethod
    def node_network_partitioning(cls, client_object, manager_ip=None,
                                  operation=None):
        client_object.connection.login_to_st_en_terminal(expect=['#'])
        if operation == 'set':
            endpoint = "iptables -I INPUT -s %s -j DROP; " \
                       "iptables -I OUTPUT -d %s -j DROP" \
                       % (manager_ip, manager_ip)
        elif operation == 'reset':
            endpoint = "iptables -D INPUT -s %s -j DROP; " \
                       "iptables -D OUTPUT -d %s -j DROP" \
                       % (manager_ip, manager_ip)
        else:
            raise ValueError("Received unknown <%s> node network "
                             "partitioning operation"
                             % operation)
        expect_prompt = ['>', '#']
        client_object.connection.request(endpoint, expect_prompt)

        # Close the expect connection object
        client_object.connection.close()

    @classmethod
    def verify_version(cls, client_obj, **kwargs):
        endpoint = "show version"
        parser = "raw/showVersion"
        expect_prompt = ['bytes*', '>']

        mapped_pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')
        return mapped_pydict

    @classmethod
    def verify_application_version(cls, client_obj, application_name,
                                   **kwargs):
        client_obj.connection.login_to_st_en_terminal(expect=['#'])

        if (application_name == "autoconf" or application_name == "bison" or
                application_name == "gcc" or application_name == "python" or
                application_name == "libtool" or application_name == 'vim' or
                application_name == "perl"):
            endpoint = application_name + " --version"
        elif application_name == "java" or application_name == "rsyslogd":
            endpoint = application_name + " -version"
        elif application_name == "kernel":
            endpoint = "cat /proc/version"
        elif application_name == "erlang":
            endpoint = "cat /usr/lib/erlang/releases/RELEASES"
        elif application_name == "rabbitmq":
            endpoint = "su - urabbit -c \"/usr/sbin/rabbitmqctl status" \
                       " | grep RabbitMQ\""

        parser = "raw/applicationVersion"
        expect_prompt = ['>', '#']
        mapped_pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         application_name)
        client_obj.connection.logout_of_st_en_terminal()
        client_obj.connection.close()
        return mapped_pydict

    @classmethod
    def verify_application_processes(cls, client_obj, application_name,
                                     **kwargs):
        client_obj.connection.login_to_st_en_terminal(expect=['#'])

        app_dict = {"appmgmt": "ps -eo user,cmd | "
                               "grep appmgmt-tcserver | wc -l",
                    "locator": "ps -eo user,cmd | grep ulocator |"
                               " grep clustering-utils | wc -l",
                    "ntp": "ps -eo user,cmd | grep /usr/sbin/ntpd | wc -l",
                    "proton": "ps -eo user,cmd | grep uproton | "
                              "grep proton-tcserver | wc -l",
                    "proxy": "ps -eo user,cmd | grep urproxy | "
                             "grep proxy-tcserver| wc -l",
                    "rabbitmq": "ps -U urabbit | wc -l",
                    "snmp": "ps -eo user,cmd | grep /usr/local/sbin/snmpd |"
                            " wc -l",
                    "sshd": "ps -eo user,cmd | grep /usr/sbin/sshd | wc -l",
                    "syslog": "ps -eo user,cmd | "
                              "grep /usr/local/sbin/rsyslogd | wc -l"}

        endpoint = app_dict[application_name]
        parser = "raw/applicationProcess"
        expect_prompt = [']', '#']
        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_obj.connection, endpoint, parser, expect_prompt,
            application_name)
        client_obj.connection.close()
        return mapped_pydict

    @classmethod
    def verify_show_interface(cls, client_obj, vnic_name, **kwargs):
        endpoint = "show interface " + vnic_name
        parser = "raw/showInterfaceNSX"
        expect_prompt = ['bytes*', '>']

        func1 = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func1(client_obj.connection,
                              endpoint, parser, expect_prompt, vnic_name)

        return mapped_pydict

    @classmethod
    def show_interfaces(cls, client_obj, **kwargs):
        endpoint = "show interfaces "
        parser = "raw/showInterfacesNSX"
        expect_prompt = ['bytes*', '>']

        func1 = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func1(client_obj.connection,
                              endpoint, parser, expect_prompt, '')

        return mapped_pydict

    @classmethod
    def read_clock_output(cls, client_obj, read_clock_output=None):
        _ = read_clock_output
        pydict = dict()
        time_pattern = '%H:%M:%S %d %m %Y'

        # Run show clock CLI on NSXManager
        endpoint = "get clock"
        parser_show_clock = "raw/showClock"
        expect_prompt = ['bytes*', '>']

        mapped_pydict_show_clock = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser_show_clock,
                                         expect_prompt,
                                         ' ')
        schema_object_clock = \
            clock_schema.ClockSchema(mapped_pydict_show_clock)
        pydict_clock = schema_object_clock.get_py_dict_from_object()

        pydict.update({'hr_min_sec': pydict_clock['hr_min_sec']})
        pydict.update({'date': pydict_clock['date']})
        pydict.update({'month': pydict_clock['month']})
        pydict.update({'year': pydict_clock['year']})
        pydict.update({'timezone': pydict_clock['timezone']})

        # Convert show clock output into epoch timestamp
        nsxmanager_clock_epoch = cls._get_epoch(pydict_clock, time_pattern)

        # Run system date command with root prompt for verification
        client_obj.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = 'date'
        parser_sys_date = "raw/sysDate"
        expect_prompt = ['bytes*', '#']

        mapped_pydict_sys_date = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser_sys_date,
                                         expect_prompt,
                                         ' ')
        schema_object_date = clock_schema.ClockSchema(mapped_pydict_sys_date)
        pydict_date = schema_object_date.get_py_dict_from_object()

        # Convert system date output into epoch timestamp
        system_date_epoch = cls._get_epoch(pydict_date, time_pattern)

        if pydict_date['timezone'] != pydict_clock['timezone']:
            pylogger.debug("Timezone mismatched")
            return pydict
        epoch_diff = system_date_epoch - nsxmanager_clock_epoch
        pydict.update({'clock_difference': epoch_diff})

        return pydict

    @classmethod
    def verify_show_certificate(cls, client_obj, thumbprint, **kwargs):
        if thumbprint is None:
            endpoint = "show api certificate"
        else:
            endpoint = "show api certificate " + thumbprint
        parser = "raw/showApiCertificate"
        expect_prompt = ['bytes*', '>']

        func1 = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func1(client_obj.connection,
                              endpoint, parser, expect_prompt, thumbprint)
        return mapped_pydict

    @classmethod
    def get_system_config(cls, client_obj, system_parameter,
                          get_system_config=None):
        _ = get_system_config
        endpoint = "get " + system_parameter
        parser = "raw/showSystemConfig"
        expect_prompt = ['bytes*', '>']

        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, system_parameter, ' ')

        if system_parameter == 'uptime':
            time_update_begin = mapped_pydict['time_update']
            time.sleep(60)
            next_pydict = func(client_obj.connection, endpoint, parser,
                               expect_prompt, system_parameter, ' ')
            time_update_end = next_pydict['time_update']
            valid_up_time = 'False'
            array_length = len(time_update_begin)
            for itr in time_update_end:
                while array_length > 0:
                    if time_update_end[array_length - 1] > \
                            time_update_begin[array_length - 1]:
                        valid_up_time = 'True'
                        break
                    array_length -= 1

            mapped_pydict.update({'valid_up_time': valid_up_time})
        return mapped_pydict

    @classmethod
    def set_clock_nsxmgr(cls, client_obj, **kwargs):

        # Preparing clock set CLI endpoint
        endpoint = "clock set " + kwargs['hr_min_sec'] + " " + \
            str(kwargs['date']) + " " + kwargs['month'] + " " \
            + str(kwargs['year'])

        # Executing CLI
        client_obj.connection.request("configure terminal", ['bytes*', '#'])
        client_obj.connection.request(endpoint, ['bytes*', '#'])
        return True

    @classmethod
    def verify_clock_set(cls, client_obj, **kwargs):
        pydict = dict()
        time_pattern = '%H:%M:%S %d %m %Y'

        # Convert time into epoch timestamp
        kwargs_clock_epoch = cls._get_epoch(kwargs, time_pattern)

        # Run show clock CLI on NSXManager to verify updated time
        endpoint = "show clock"
        parser_show_clock = "raw/showClock"
        expect_prompt = ['bytes*', '>']

        mapped_pydict_show_clock = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser_show_clock,
                                         expect_prompt,
                                         ' ')
        schema_object_clock = \
            clock_schema.ClockSchema(mapped_pydict_show_clock)
        pydict_clock = schema_object_clock.get_py_dict_from_object()

        # Convert NSXManager clock to epoch timestamp
        system_date_epoch = cls._get_epoch(pydict_clock, time_pattern)

        if kwargs['timezone'] != pydict_clock['timezone']:
            pylogger.debug("Timezone mismatched")
            return pydict

        epoch_diff = system_date_epoch - kwargs_clock_epoch
        pydict.update({'clock_difference': epoch_diff})

        return pydict

    @classmethod
    def _get_epoch(cls, clock_pydict, time_pattern):

        if not clock_pydict['month'].isdigit():
            clock_pydict.update(
                {'month': time.strptime(clock_pydict['month'], '%b').tm_mon})

        # Prepare clock output string acceptable epoch timestamp conversion
        clock_str = clock_pydict['hr_min_sec'] + ' ' + clock_pydict['date'] +\
            ' ' + str(clock_pydict['month']) + ' ' + clock_pydict['year']

        pylogger.debug("Clock output to get epoch timestamp: \
          [%s]" % clock_str)

        # Converting clock output to epoch time
        epoch = \
            int(time.mktime(time.strptime(clock_str, time_pattern)))

        return epoch

    @classmethod
    def list_commands(cls, client_obj, terminal='false', **kwargs):
        endpoint = "list"
        parser = "raw/listCommands"
        expect_prompt = ['bytes*', '>']

        if terminal == 'true':
            client_obj.connection.request("configure terminal",
                                          ['bytes*', '#'])
            expect_prompt = ['bytes*', '#']

        pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')

        return pydict

    @classmethod
    def get_content(cls, client_obj, content_type='help', **kwargs):

        if content_type == 'help':
            endpoint = "help"
            expect_prompt = ['bytes*', '#']
            client_obj.connection.request("configure terminal", expect_prompt)
        elif content_type == 'log':
            if kwargs['file_name'] is None:
                raise ValueError('file_name parameter is missing')
            endpoint = "show log %s" % kwargs['file_name']
            expect_prompt = ['--More--', '>']
        else:
            raise ValueError("Incorrect content_type: %s" % content_type)

        pydict = dict()

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data

        pydict.update({'content': raw_payload})
        return pydict

    @classmethod
    def list_log_files(cls, client_obj, **kwargs):
        endpoint = "get log ?"
        parser = "raw/listLogFiles"
        expect_prompt = ['bytes*', '>']

        pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')

        return pydict

    @classmethod
    def trace_route(cls, client_obj, hostname=None, **kwargs):
        endpoint = "traceroute %s" % hostname
        parser = "raw/showTraceRoute"
        expect_prompt = ['bytes*', '>']

        pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')

        return pydict

    @classmethod
    def set_hostname(cls, client_obj, **kwargs):

        # Set hostname
        endpoint = "set hostname " + kwargs['hostname']
        expect_prompt = ['bytes*', '>']

        pylogger.debug("CLI send to set hostname: [%s]" % endpoint)
        client_obj.connection.request(endpoint, expect_prompt)

        return common.status_codes.SUCCESS

    @classmethod
    def read_hostname(cls, client_obj, **kwargs):
        endpoint = "get hostname"
        parser = "raw/showHostname"
        expect_prompt = ['bytes*', '>']

        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, ' ')
        return mapped_pydict

    @classmethod
    def run_command(cls, client_obj, **kwargs):

        if kwargs['command'] is None:
            raise ValueError("Required parameter [command] not provided.")

        endpoint = kwargs['command']
        expect_prompt = ['bytes*', '#']

        if 'terminal' in kwargs and kwargs['terminal'] == 'true':
            client_obj.connection.request("configure terminal", expect_prompt)

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data

        lines = raw_payload.strip().split("\n")

        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0))):
            return {'status': 1}

        return {'status': 0}

    @classmethod
    def exit_from_terminal(cls, client_obj, **kwargs):

        raw_payload = client_obj.connection.request(
            "show hostname", ['bytes*', '>']).response_data
        hostname = raw_payload.splitlines()[0]

        if kwargs['command'] is None:
            raise ValueError("Required parameter [command] not provided.")

        if kwargs['command'] == 'end':
            expect_prompt = ['bytes*', '>']
            expect_prompt_str = hostname
        elif kwargs['command'] == 'exit':
            expect_prompt = ['bytes*', '#']
            expect_prompt_str = hostname + "(config)"
        else:
            raise ValueError(
                "Incorrect parameter value passed: %s" % kwargs['command'])

        client_obj.connection.request("configure terminal", ['bytes*', '#'])
        client_obj.connection.request("interface mgmt", ['bytes*', "#"])

        raw_payload = client_obj.connection.request(
            kwargs['command'], expect_prompt).response_data

        lines = raw_payload.strip().split("\n")

        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0))):
            return {'status': 1}

        # Verify the expected prompt string
        if lines[0] != expect_prompt_str:
            return {'status': 1}

        return {'status': 0}

    @classmethod
    def get_server_auth(cls, client_obj, **kwargs):
        endpoint = "show tacacs-server-authentication"
        parser = "raw/showTacacsServerAuth"
        expect_prompt = ['bytes*', '>']
        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, ' ')
        return mapped_pydict

    @classmethod
    def get_ip_route(cls, client_obj, **kwargs):
        raw_payload = client_obj.connection.request(
            "show ip route", ['bytes*', '>']).response_data

        ip_route_details = raw_payload.splitlines()[0]
        split_data1 = ip_route_details.split()

        client_obj.connection.login_to_st_en_terminal(expect=['#'])

        raw_payload = client_obj.connection.request(
            "route -n", ['bytes*', '#']).response_data
        route_details = raw_payload.splitlines()[2]
        split_data2 = route_details.split()

        mapped_pydict = dict()
        if split_data1[2] in split_data2[1]:
            mapped_pydict.update({'gateway_matched': '1'})
        else:
            mapped_pydict.update({'gateway_matched': '0'})

        # Close the expect connection object
        client_obj.connection.close()

        return mapped_pydict

    @classmethod
    def set_user_password(cls, client_obj, **kwargs):
        if kwargs['username'] is None and kwargs['password'] is None:
            raise ValueError(
                "Required parameter [username] and [password] not provided.")

        endpoint = "username " + kwargs['username'] + " password " + \
            kwargs['password']
        expect_prompt = ['bytes*', '#']

        pylogger.debug("CLI to set password: [%s]" % endpoint)

        client_obj.connection.request("configure terminal", expect_prompt)
        raw_payload = client_obj.connection.request(
            endpoint, expect_prompt).response_data

        # Close the expect connection object
        client_obj.connection.close()

        lines = raw_payload.strip().split("\n")

        if (len(lines) > 0) and \
                (lines[0].upper().find("DOES NOT MEET COMPLEXITY") > 0):
            pylogger.debug(
                "The given password does not meet complexity requirements")
            return False

        return True

    @classmethod
    def show_arp(cls, client_obj, show_arp=None):
        _ = show_arp
        parser = "raw/horizontalTable"

        endpoint = "get arp"
        expect_prompt = ["--More--", ">"]

        # Execute the command on the NSXManager
        raw_payload = client_obj.connection. \
            request(endpoint, expect_prompt).response_data

        # Get the parser
        data_parser = utilities.get_data_parser(parser)

        raw_payload = data_parser.marshal_raw_data(
            raw_payload, 'Hardware Addr', 'HardwareAddr')

        # Get the parsed data
        pydict = data_parser.get_parsed_data(raw_payload, skip_tail=2)

        # Close the expect connection object
        client_obj.connection.close()

        return show_arp_schema.ShowArpSchema(pydict)

    @classmethod
    def show_ip_sockets(cls, client_obj, **kwargs):
        parser = "raw/horizontalTable"

        endpoint = "show ip sockets"
        expect_prompt = ["--More--", ">"]

        # Execute the command on the NSXManager
        raw_payload = client_obj.connection. \
            request(endpoint, expect_prompt).response_data

        # Get the parser
        data_parser = utilities.get_data_parser(parser)

        # Get the parsed data
        pydict = data_parser.get_parsed_data(raw_payload, skip_tail=2)

        # Close the expect connection object
        client_obj.connection.close()

        return show_ip_sockets_schema.ShowIPSocketsSchema(pydict)

    @classmethod
    def search_log(cls, client_obj, **kwargs):

        if kwargs['file_name'] is None:
            raise ValueError('file_name parameter is missing')
        if kwargs['search_string'] is None:
            raise ValueError('search_string parameter is missing')

        endpoint = "show log %s" % kwargs['file_name']
        expect_prompt = ['--More--', 'manager>']

        pydict = dict()

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data
        if kwargs['search_string'] == "Exception":
            string_count = len(re.findall(kwargs['search_string'] + ":",
                                          raw_payload))
        else:
            string_count = len(re.findall(kwargs['search_string'],
                                          raw_payload))
        pydict.update({'string_count': string_count})
        return pydict

    @classmethod
    def get_cluster_details(cls, client_obj, **kwargs):

        endpoint = "show management-cluster status"
        expect_prompt = ['bytes *', 'manager>']
        parser = "raw/showClusterParser"

        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, ' ')

        return mapped_pydict

    @classmethod
    def get_file_systems(cls, client_obj, **kwargs):
        endpoint = "show file systems"
        expect_prompt = ['bytes*', '>']
        parser = "raw/showFileSystemsParser"

        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, ' ')
        return mapped_pydict

    @classmethod
    def verify_file_present(cls, client_obj, **kwargs):
        if kwargs['file_name'] is None:
            raise ValueError('file_name parameter is missing')

        client_obj.connection.login_to_st_en_terminal(expect=['#'])
        endpoint = "ls -l %s" % kwargs['file_name']
        expect_prompt = ['>', '#']
        parser = "raw/ShowFilePresenceParser"

        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, kwargs['file_name'])
        return mapped_pydict

    @classmethod
    def verify_password_encrypted(cls, client_obj, **kwargs):
        client_obj.connection.login_to_st_en_terminal(expect=['#'])
        endpoint = "cat /etc/passwd"
        expect_prompt = ['>', '#']
        parser = "raw/ShowPasswordParser"

        func = utilities.get_mapped_pydict_for_expect
        mapped_pydict = func(client_obj.connection, endpoint, parser,
                             expect_prompt, ' ')
        client_obj.connection.close()
        return mapped_pydict

    @classmethod
    def get_global_config(cls, client_obj, **kwargs):
        mapped_pydict = dict()

        raw_payload = client_obj.connection.request(
            "show configuration global", ['bytes*', '>']).response_data
        split_data = raw_payload.split('\n')

        hostname = split_data[1].split()
        mapped_pydict.update({'hostname': hostname[1].strip()})
        ntpserver = split_data[3].split()
        mapped_pydict.update({'ntpserver': ntpserver[2].strip()})
        authtype = split_data[4].split()
        mapped_pydict.update({'authtype': authtype[1].strip()})
        gateway1 = split_data[2].split()

        client_obj.connection.login_to_st_en_terminal(expect=['#'])

        raw_payload = client_obj.connection.request(
            "route -n", ['bytes*', '#']).response_data
        route_details = raw_payload.splitlines()[2]
        gateway2 = route_details.split()

        if gateway1[3] in gateway2[1]:
            mapped_pydict.update({'gateway_matched': '1'})
        else:
            mapped_pydict.update({'gateway_matched': '0'})

        # Close the expect connection object
        client_obj.connection.close()

        return mapped_pydict

    @classmethod
    def create_tech_support_tar(cls, client_obj, file_name=None):

        if file_name is not None:
            endpoint = "get support-bundle file " + file_name
            pylogger.debug(
                "Command to create tar file using endpoint [%s]" % endpoint)
        else:
            raise ValueError("Received empty file_name")

        expect_prompt = ["--More--", ">"]

        client_obj.connection.request(endpoint, expect_prompt)

        # Close the expect connection object
        client_obj.connection.close()
        return common.status_codes.SUCCESS

    @classmethod
    def get_dir_list(cls, client_obj, get_dir_list=None):
        """ Sample output of 'dir' CLI
        nsx-manager> dir
        Directory of filestore:/

       -rwx      126626     Dec 04 2014 07:30:05 UTC  tech.tzg
       -rwx      127268     Dec 04 2014 07:33:17 UTC  tech02.tzg
       -rwx      152582     Dec 04 2014 09:33:24 UTC  tech_support.tgz
       -rwx      162002     Dec 04 2014 10:27:17 UTC  tech_support_logs.tgz
       -rwx           0     Dec 04 2014 07:10:13 UTC  text.file

        """
        _ = get_dir_list
        endpoint = "get files"
        expect_prompt = ["--More--", ">"]

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data

        # Get the parser
        parser = "raw/horizontalTable"
        data_parser = utilities.get_data_parser(parser)

        # Creating header as CLI returns list without column name
        header_keys = \
            ['permissions', 'size', 'month', 'date', 'year', 'time', 'TZ',
             'file_name']

        raw_payload_with_header = \
            data_parser.insert_header_to_raw_data(
                raw_payload, header_keys=header_keys, skip_head=2)

        pydict = data_parser.get_parsed_data(
            raw_payload_with_header, header_keys=header_keys, skip_head=2,
            skip_tail=1)

        # Close the expect connection object
        client_obj.connection.close()

        return dir_schema.DirSchema(pydict)

    @classmethod
    def get_ping_output(cls, client_obj, ip=None, hostname=None,
                        get_ping_output=None):
        _ = get_ping_output
        if ip is not None:
            endpoint = "ping " + ip
        elif hostname is not None:
            endpoint = "ping " + hostname
        else:
            raise ValueError("Received empty hostname/IP")

        expect_prompt = ["--More--", ">"]

        # 'Ctrl + C' required to terminate the ping execution
        control_key = 'c'

        # Sleeping for 5 seconds to collect sizable ping responses
        sleep = 5

        raw_payload = client_obj.connection.request(
            endpoint, expect_prompt, control_key, sleep).response_data

        # Close the expect connection object
        client_obj.connection.close()

        # Get the parser
        parser = "raw/pingHost"
        data_parser = utilities.get_data_parser(parser)

        pydict = data_parser.get_parsed_data(raw_payload)

        return pydict

    @classmethod
    def delete_file(cls, client_obj, **kwargs):
        if kwargs['file_name']:
            endpoint = "delete " + kwargs['file_name']
            expect_prompt = ["--More--", ">"]
        else:
            raise ValueError("Received empty file_name")

        try:
            client_obj.connection.request(endpoint, expect_prompt)
            return common.status_codes.SUCCESS

        except Exception, error:
            pylogger.exception("Failed to run CLI: %s" % error)
            return common.status_codes.FAILURE

    @classmethod
    def debug_packet_capture(cls, client_obj, **kwargs):

        if kwargs['vnic_name']:
            endpoint_start_debug = \
                "debug packet capture interface " + kwargs['vnic_name']
            endpoint_stop_debug = \
                "no debug packet capture interface " + kwargs['vnic_name']
            expect_prompt = ["--More--", ">"]
        else:
            raise ValueError("Received empty vnic_name")

        # Delete file if already present
        file_name = kwargs['vnic_name'] + '.pcap'
        cls.delete_file(client_obj, file_name=file_name)

        try:
            client_obj.connection.request(endpoint_start_debug, expect_prompt)

            # Sleeping for 5 seconds to capture sizable data
            time.sleep(5)

            client_obj.connection.request(endpoint_stop_debug, expect_prompt)

            # Close the expect connection object
            client_obj.connection.close()
            return common.status_codes.SUCCESS

        except Exception, error:
            pylogger.exception("Failed to run CLI: %s" % error)
            return common.status_codes.FAILURE

    @classmethod
    def set_banner_motd(cls, client_obj, **kwargs):
        # ###
        # nsx-manager> configure terminal
        # nsx-manager(config)# banner motd
        # Enter TEXT message.  End with 'Ctrl-D'
        # Hello World!!
        # nsx-manager(config)#
        # ###

        if not kwargs['message']:
            raise ValueError("Received empty message")

        try:
            endpoint = "banner motd"
            ctrl_key = 'd'

            client_obj.connection.request(
                "configure terminal", ['bytes*', '#'])
            client_obj.connection.request(endpoint, ["--More--", "\'Ctrl-D\'"])
            client_obj.connection.request(
                kwargs['message'], ["--More--", "\r\n", "#"], ctrl_key)

            # Close the expect connection object
            client_obj.connection.close()
            return common.status_codes.SUCCESS

        except Exception:
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

    @classmethod
    def get_motd(cls, client_obj, **kwargs):
        # ###
        # nsx-manager> st e
        # Password:
        # [root@nsx-manager ~]# cat /etc/motd.tail
        # Hello World!!
        # [root@nsx-manager ~]#
        # ###

        pydict = dict()
        client_obj.connection.login_to_st_en_terminal(expect=['#'])
        endpoint = "cat /etc/motd.tail"
        expect_prompt = ['bytes *', '#']

        try:
            raw_payload = client_obj.connection.request(
                endpoint, expect_prompt).response_data

            pydict.update({'message': raw_payload})
            # Close the expect connection object
            client_obj.connection.close()
            return pydict

        except Exception:
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

    @classmethod
    def get_process_monitor(cls, client_obj, **kwargs):
        endpoint = "show process monitor"
        expect_prompt = ["#", ">", "\'"]
        ctrl_key = 'C'
        wait = 2

        raw_payload = client_obj.connection.request(
            endpoint, expect_prompt, ctrl_key, wait).response_data

        parser = "raw/showProcessMonitor"
        data_parser = utilities.get_data_parser(parser)

        pydict = data_parser.get_parsed_data(raw_payload)

        return show_process_monitor_schema.ShowProcessMonitorSchema(pydict)

    @classmethod
    def read_system_memory(cls, client_obj, **kwargs):
        client_obj.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "cat /proc/meminfo"
        parser = "raw/systemMeminfo"
        expect_prompt = ['bytes*', '#']

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data

        data_parser = utilities.get_data_parser(parser)
        client_obj.connection.close()
        return data_parser.get_parsed_data(raw_payload)

    @classmethod
    def set_ntp_server(cls, client_obj, ip=None, hostname=None, reset=None,
                       **kwargs):

        client_obj.connection.request("configure terminal", ['bytes*', '#'])
        if (((ip is None and hostname is None) or
             (ip is not None and hostname is not None))):
            raise ValueError("Need to provide either ip or hostname, but "
                             "provided ip=%s, hostname=%s" % (ip, hostname))

        endpoint = "ntp server %s" % (ip or hostname)
        # NTP server reset mode
        if utilities.is_true(reset):
            endpoint = "no " + endpoint

        expect_prompt = ["--More--", "#"]
        try:
            client_obj.connection.request(endpoint, expect_prompt)
            client_obj.connection.close()
            return common.status_codes.SUCCESS
        except Exception, e:
            raise errors.CLIError(
                status_code=common.status_codes.FAILURE, exc=e)

    @classmethod
    def get_ntp_associations(cls, client_obj, **kwargs):
        """
        vdnet-nsxmanager(config)# show ntp associations
             remote           local      st poll reach  delay   offset    disp
        =======================================================================
        *LOCAL(0)        127.0.0.1        3   64    1 0.00000  0.000000 2.81735
        =scrootdc02.vmwa 10.110.31.231    2   64    1 0.21999 -8.864582 2.81874
        """

        endpoint = "show ntp associations"
        expect_prompt = ['bytes *', '>']

        raw_payload = client_obj.connection.request(
            endpoint, expect_prompt).response_data

        # Get the parser
        parser = "raw/horizontalTable"
        data_parser = utilities.get_data_parser(parser)

        # Horizontal table parser doesn't support any particular line deletion
        # in the table. Removing  first two lines and creating a new header
        header_keys = \
            ['remote', 'local', 'st', 'poll', 'reach', 'delay', 'offset',
             'disp']

        raw_payload_with_header = \
            data_parser.insert_header_to_raw_data(
                raw_payload, header_keys=header_keys, skip_head=2)

        pydict = data_parser.get_parsed_data(
            raw_payload_with_header, skip_head=2, skip_tail=1)

        # Close the expect connection object
        client_obj.connection.close()
        return show_ntp_associations_schema.ShowNtpAssociationsSchema(pydict)

    @classmethod
    def configure_ip_route(cls, client_obj, **kwargs):

        client_obj.connection.request("configure terminal", ['bytes*', '#'])

        if kwargs['cidr'] and kwargs['manager_ip']:
            endpoint = \
                "ip route " + kwargs['cidr'] + " " + kwargs['manager_ip']
        else:
            raise ValueError("Received empty cidr/manager_ip")

        # Reset mode
        if 'reset' in kwargs and \
                (kwargs['reset'].lower() == 'yes' or
                 kwargs['reset'].lower() == 'true'):
            endpoint = "no " + endpoint

        expect_prompt = ["--More--", "#"]

        try:
            client_obj.connection.request(endpoint, expect_prompt)

            # Close the expect connection object
            client_obj.connection.close()
            return common.status_codes.SUCCESS

        except Exception:
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

    @classmethod
    def show_ip_route(cls, client_obj, **kwargs):
        """
        nsxmanager> show ip route
        default via 10.112.11.253 dev mgmt  metric 203
        10.112.10.0/23 via 10.112.11.253 dev mgmt
        10.112.10.0/23 dev mgmt  proto kernel  scope link  src 10.112.11.27
          metric 203
        """

        endpoint = "show ip route"
        expect_prompt = ['bytes *', '>']

        if 'cidr' in kwargs:
            if kwargs['cidr']:
                endpoint = endpoint + " " + kwargs['cidr']
            else:
                raise ValueError("Received empty cidr")

        raw_payload = client_obj.connection.request(
            endpoint, expect_prompt).response_data

        # Close the expect connection object
        client_obj.connection.close()

        # Get the parser
        parser = "raw/showIpRoute"
        data_parser = utilities.get_data_parser(parser)

        return data_parser.get_parsed_data(raw_payload)

    @classmethod
    def configure_tacacs_server(cls, client_obj, **kwargs):

        client_obj.connection.request("configure terminal", ['bytes*', '#'])

        if kwargs['address'] and kwargs['secret_key']:
            endpoint = "tacacs-server  " + kwargs['address'] + " " + \
                       kwargs['secret_key']
        else:
            raise ValueError("Received empty address/secret key field")

        expect_prompt = ["--More--", "#"]

        try:
            client_obj.connection.request(endpoint, expect_prompt)

            # Close the expect connection object
            client_obj.connection.close()
            return common.status_codes.SUCCESS

        except Exception:
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

    @classmethod
    def configure_auth_type(cls, client_obj, **kwargs):

        client_obj.connection.request("configure terminal", ['bytes*', '#'])

        if kwargs['auth_type']:
            endpoint = "tacacs-server-authentication  " + kwargs['auth_type']
        else:
            raise ValueError("Received empty type field")

        expect_prompt = ["--More--", "#"]

        try:
            client_obj.connection.request(endpoint, expect_prompt)

            # Close the expect connection object
            client_obj.connection.close()
            return common.status_codes.SUCCESS

        except Exception:
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

    @classmethod
    def copy_file(cls, client_obj, **kwargs):

        if kwargs['username'] and kwargs['path'] and kwargs['password']\
                and kwargs['ifname']:
            username = kwargs['username']
            path = kwargs['path']
            password = kwargs['password']
            launcher_ip = utilities.get_launcher_ip(kwargs['ifname'])
        else:
            raise ValueError(
                "Required parameter username/path/password/ifname missing")

        # Copy file from NSXManager to the specified URL
        if 'source_file_name' in kwargs and kwargs['source_file_name']:
            file_path = path + "/" + kwargs['source_file_name']

            # Create directory on launcher if not already present
            if not os.path.exists(path):
                try:
                    os.makedirs(path)
                except OSError, e:
                    pylogger.exception("Failed to create directory: %s - %s"
                                       % e.filename % e.strerror)
                    raise

            # Remove file if already present on launcher
            if os.path.isfile(file_path):
                try:
                    os.remove(file_path)
                except OSError, e:
                    pylogger.exception("Failed to remove file: %s - %s"
                                       % e.filename % e.strerror)
                    raise

            endpoint = "copy " + kwargs['source_file_name'] + " scp://"
            endpoint = endpoint + username + "@" + launcher_ip + path

        # Copy file from the specified URL to NSXManager
        elif 'dest_file_name' in kwargs and kwargs['dest_file_name']:
            endpoint = "copy scp://" + username + "@" + launcher_ip + path
            endpoint = endpoint + "/" + kwargs['dest_file_name']
            endpoint = endpoint + " " + kwargs['dest_file_name']

            file_path = path + "/" + kwargs['dest_file_name']
        else:
            raise ValueError("Required parameter source_file_name/"
                             "dest_file_name is missing/empty")

        try:
            pylogger.debug("Command executed to copy file: [%s]" % endpoint)
            client_obj.connection.execute_command_with_hostkey_prompt(
                command=endpoint, remote_password=password,
                final_expect=['>'])

            # verify file exists after copy from NSXManager
            if 'source_file_name' in kwargs and kwargs['source_file_name']:
                if not os.path.isfile(file_path):
                    return common.status_codes.FAILURE

            # Delete file after copy from launcher to NSXManager if requested
            if 'dest_file_name' in kwargs and kwargs['dest_file_name']:
                if "delete_file_after_copy" in kwargs \
                        and kwargs['delete_file_after_copy'] == "yes":
                    if os.path.isfile(file_path):
                        try:
                            os.remove(file_path)
                        except OSError, e:
                            pylogger.exception("Failed to remove file: %s - %s"
                                               % e.filename % e.strerror)
                            raise
            return common.status_codes.SUCCESS

        except Exception:
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

    @classmethod
    def move_file(cls, client_object, source_path, destination_path, file_name,
                  dest_file_name):
        client_object.connection.login_to_st_en_terminal(expect=['#'])
        endpoint = 'mv' + ' ' + source_path + '/' + file_name + ' ' + \
                   destination_path + '/' + dest_file_name
        expect_prompt = ['>', '#']
        pylogger.debug("Command executed to move file: [%s]" % endpoint)
        client_object.connection.request(endpoint, expect_prompt)
        return

    @classmethod
    def delete_backend_file(cls, client_object, path, file_name):
        client_object.connection.login_to_st_en_terminal(expect=['#'])
        endpoint = 'rm ' + ' ' + path + '/' + file_name
        expect_prompt = ['>', '#']
        pylogger.debug("Command executed to delete file: [%s]" % endpoint)
        result = client_object.connection.request(endpoint, expect_prompt)
        response = result.response_data
        if 'No such file or directory' in response:
            pylogger.debug("%s file_name does not exist, skipping delete")
            return common.status_codes.SUCCESS
        if 'cannot remove' in response:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=response)
        else:
            return common.status_codes.SUCCESS

    @classmethod
    def check_cluster_backup_file(cls, client_object, path, **kwargs):
        if path:
            endpoint = 'ls -l ' + path
        else:
            raise ValueError("Received empty path")

        pylogger.debug("Command executed to check file: [%s]" % endpoint)

        client_object.connection.login_to_st_en_terminal(expect=['#'])

        expect_prompt = ['>', '#']

        endpoint1 = 'cd ' + path + ' && ls -L | wc -l'
        result = client_object.connection.request(endpoint1, expect_prompt)
        response = result.response_data
        lines = response.strip().split("\n")

        if (len(lines) > 0) and (lines[0] == '1'):
            raw_payload = client_object.\
                connection.request(endpoint, expect_prompt).response_data
            client_object.connection.close()

            lines = raw_payload.strip().split("\n")
            pydict = dict()

            if (len(lines) > 0) and ("backup_" in lines[1]):
                pydict.update({'content': 'found'})
                return pydict

            pylogger.exception("backup file not found")
            pydict.update({'content': 'error'})
            return pydict
        else:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason='More than one backup file found')

    @classmethod
    def check_node_backup_file(cls, client_object, path, **kwargs):

        if path:
            endpoint = 'ls -l ' + path
        else:
            raise ValueError("Received empty path")

        pylogger.debug("Command executed to check file: [%s]" % endpoint)

        client_object.connection.login_to_st_en_terminal(expect=['#'])

        expect_prompt = ['>', '#']

        raw_payload = client_object.connection.request(
            endpoint, expect_prompt).response_data
        client_object.connection.close()

        lines = raw_payload.strip().split("\n")
        pydict = dict()

        if len(lines) > 0:
            pydict.update({'content': raw_payload})
            return pydict
        else:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason='Node backup file not found')

    @classmethod
    def node_cleanup(cls, client_object):
        script_path = constants.ManagerScriptPath.NSXNODECLEANUPSCRIPTPATH
        endpoint = 'chmod 755 ' + script_path
        client_object.connection.login_to_st_en_terminal(expect=['#'])
        expect_prompt = ['>', '#']
        pylogger.debug("Command executed to change "
                       "the permission of file: [%s]" % endpoint)
        result = client_object.connection.request(endpoint, expect_prompt)
        response = result.response_data
        if 'No such file or directory' in response:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=response)
        else:
            endpoint = script_path
            expect_prompt = ['>', '#']
            pylogger.debug("Command executed to run "
                           "the mp node cleanup script: [%s]" % endpoint)
            result = client_object.connection.request(endpoint, expect_prompt)
            response = result.response_data
            # Close the expect connection object
            client_object.connection.close()
            if response.find("Unable to stop") > 0:
                pylogger.error("Failed to run the cleanup script")
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=response)
            else:
                return common.status_codes.SUCCESS
