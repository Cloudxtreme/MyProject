import os
import sys
import pexpect
import re
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.os_interface as os_interface
import vmware.schema.gateway.show_edge_version_schema as \
    show_edge_version_schema

pylogger = global_config.pylogger


class Edge70OSImpl(os_interface.OSInterface):

    path_rel = os.path.dirname(
        os.path.realpath(sys.argv[0])) + "/VDNetLib/TestData/Edge/"

    @classmethod
    def get_os_info(cls, client_object, **kwargs):

        """
        Returns the Kernel version, Build number, Name and Version
        information for given NSX edge

        NSXEdge>show version
        ... Name: NSX Edge
        ... Version: 7.0.0.0.0
        ... Build Number: 2252106
        ... Kernel: 3.2.62

        """

        endpoint = "show version "
        PARSER = "raw/showEdgeVersion"
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']

        # Get the parsed data
        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, PARSER, EXPECT_PROMPT, ' ')

        # Close the expect connection object
        client_object.connection.close()

        get_edge_version_schema_object = show_edge_version_schema. \
            ShowEdgeVersionSchema(mapped_pydict)
        pylogger.info("show version command output : %s" %
                      get_edge_version_schema_object.__dict__)
        return get_edge_version_schema_object

    @classmethod
    def get_license_string(cls, client_object, **kwargs):

        """

        Returns True the License Agreement information gets
        displayed for given NSX edge; else returns False

        """

        ssh_string = ('ssh -o UserKnownHostsFile=/dev/null -o '
                      'StrictHostKeyChecking=no %s@%s' %
                      (client_object.username, client_object.ip))
        client_object.pexpectconn = pexpect.spawn(ssh_string)
        client_object.pexpectconn.setecho(False)
        pexpect_status = client_object.pexpectconn.expect([pexpect.TIMEOUT,
                                                           'password:',
                                                           'Password:'])

        if pexpect_status == 0:  # Timeout
            pylogger.error('ERROR! could not login with SSH using pexpect :')
            pylogger.error(client_object.pexpectconn.before,
                           client_object.pexpectconn.after)
            pylogger.error(str(client_object.pexpectconn))
            return None

        raw_payload = client_object.pexpectconn.before

        client_object.anchor = client_object.pexpectconn

        # Close the expect connection object
        client_object.connection.close()

        pydict = {}
        result = re.search("NOTICE TO USERS", raw_payload, re.I)

        if result:
            pydict['license'] = 'true'

        return pydict

    @classmethod
    def get_all_supported_commands_configure_mode(cls, client_object,
                                                  **kwargs):
        """
        Logs in to given NSX edge in configure terminal mode and
        fetch the list of all supported commands.
        Returns the list of commands in a pyset object.

        Refer /VDNetLib/TestData/Edge/list_command_configure_mode
        for output format
        """
        pydict = dict()

        try:
            if "password" in kwargs:
                pwd = kwargs["password"]
                pylogger.info("trying to create an expect connection "
                              "with %s" % pwd)
            else:
                pwd = constants.VSMterms.PASSWORD

            # Execute the command on the Edge VM
            expect_condition, command_output = client_object.connection.\
                execute_command_in_configure_terminal("list", ['#'],
                                                      enable_password=pwd)
        except:
            # Close the expect connection object
            client_object.connection.close()

            pydict['result'] = False
            return pydict

        # Close the expect connection object
        client_object.connection.close()

        error_occured = command_output.find('Error')

        if expect_condition == 0:  # expecting the '#' prompt
            if error_occured == -1:

                pylogger.info("Successfully listing configure mode commands")
                lines = command_output.split("\n")
                lines = [i.strip() for i in lines]
                if "NSXEdge(config)" in lines:
                    lines.remove("NSXEdge(config)")

                pydict['supported_commands'] = set(lines)
                return pydict
            else:
                raise RuntimeError("Unable to list config mode commands")
        else:
            raise RuntimeError("Unable to establish expect connection")

    @classmethod
    def get_all_supported_commands_enable_mode(
            cls, client_object, **kwargs):
        """
        Logs in to given NSX edge in enable mode with specified credentials
        and fetches the list of all supported commands.
        Returns the list of commands in a pyset object.

        Refer /VDNetLib/TestData/Edge/list_command_enable_mode
        for output format
        """
        pydict = dict()

        try:
            if "password" in kwargs:
                password = kwargs["password"]
                pylogger.info("trying to create an expect connection "
                              "with %s" % password)

                # Execute the command on the Edge VM
                expect_condition, command_output = client_object.connection.\
                    execute_command_in_enable_terminal("list", ['#'],
                                                       password=password)

            else:
                # Execute the command on the Edge VM
                expect_condition, command_output = client_object.connection.\
                    execute_command_in_enable_terminal("list", ['#'])

        except:
            # Close the expect connection object
            client_object.connection.close()

            pydict['result'] = False
            return pydict

        # Close the expect connection object
        client_object.connection.close()

        # Fetching the Error string if any
        error_occured = command_output.find('Error')

        if expect_condition == 0:  # expecting the '#' prompt
            if error_occured == -1:

                pylogger.info("Successfully listing enable mode commands")
                lines = command_output.strip().split("\n")
                lines = [i.strip() for i in lines]
                if "NSXEdge" in lines:
                    lines.remove("NSXEdge")

                pydict['supported_commands'] = set(lines)
                return pydict
            else:
                raise RuntimeError("Unable to list enable mode commands")
        else:
            pydict['result'] = False
            return pydict

    @classmethod
    def get_all_supported_commands_admin_mode(
            cls, client_object, **kwargs):
        """
        Logs in to given NSX edge in admin mode with specified credentials
        and fetches the list of all supported commands.
        Returns the list of commands in a pyset object.

        Refer /VDNetLib/TestData/Edge/list_command_admin_mode
        for output format
        """
        pydict = dict()
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']

        try:
            if "password" in kwargs:
                password = kwargs["password"]
                pylogger.info("trying to create an expect connection "
                              "with %s" % password)

                client_object.password = password

                # Execute the command on the Edge VM
                command_output = client_object.connection.\
                    request("list", EXPECT_PROMPT).response_data

            else:
                # Execute the command on the Edge VM
                command_output = client_object.connection.\
                    request("list", EXPECT_PROMPT).response_data

        except:
            pydict['result'] = False
            return pydict

        # Close the expect connection object
        client_object.connection.close()

        # Fetching the Error string if any
        error_occured = command_output.find('Error')

        if error_occured == -1:

            pylogger.info("Successfully listing admin mode commands")
            lines = command_output.strip().split("\n")
            lines = [i.strip() for i in lines]
            if "NSXEdge" in lines:
                lines.remove("NSXEdge")

            pydict['supported_commands'] = set(lines)
            return pydict
        else:
            raise RuntimeError("Unable to list admin mode commands")


if __name__ == '__main__':
    import doctest
    doctest.testmod()
