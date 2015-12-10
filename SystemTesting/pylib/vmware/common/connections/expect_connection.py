import os
import pexpect
import tempfile
import time

import vmware.common as common
import vmware.common.errors as errors
import vmware.common.connection as connection
import vmware.common.global_config as global_config
import vmware.common.result as result
import vmware.common.compute_utilities as compute_utilities
import vmware.common.constants as constants
import vmware.common.utilities as utilities

pylogger = global_config.pylogger
# If CLI output has the first character as % then the command failed.
err_chars = ['%']
PASSWORD_PROMPTS = ['password:', 'Password:']
TERMINAL_PROMPTS = ['.#', '.>', ']']
HOSTKEY_PROMPT = 'you want to continue connecting (yes/no)?'


class ExpectConnection(connection.Connection):
    """ Class to create expect connection and request and get response
    for queries
    """
    NEXT_PAGE_PROMPT = 0
    EXPECT_PROMPT = 1

    def __init__(self, ip="", username="", password="",
                 root_password="", connection_object=None,
                 terminal_prompts=None):
        super(ExpectConnection, self).\
            __init__(ip, username, password, root_password, connection_object)
        self.terminal_prompts = utilities.get_default(terminal_prompts,
                                                      TERMINAL_PROMPTS)

    def create_connection(self, expect=None):
        if expect is None:
            expect = self.terminal_prompts
        ssh_string = ('ssh -o UserKnownHostsFile=/dev/null -o '
                      'StrictHostKeyChecking=no %s@%s' % (self.username,
                                                          self.ip))
        expect = [pexpect.TIMEOUT, pexpect.EOF] + PASSWORD_PROMPTS + expect
        self.pexpectconn = pexpect.spawn(ssh_string)
        self.pexpectconn.setecho(False)
        pexpect_status = self.pexpectconn.expect(expect)
        err_msg = "Could not login using pexpect to %r as %s"
        # Ordering is checked in the following specific order,
        # 1. Continuity steps for host key/password prompts
        # 2. Erroneous checks like EOF/Timeout
        # 3. Final expect prompt check
        if pexpect_status in (2, 3):  # Password prompts first
            self.pexpectconn.sendline(self.password)
            pexpect_status = self.pexpectconn.expect(expect)
        if pexpect_status == 0:  # Timeout
            err_msg = "Pexpect timed out when trying to connect to %r as %r"
        if pexpect_status == 1:  # EOF found
            err_msg = "Pexpect received EOF when trying to connect to %r as %r"
        if pexpect_status in (4, 5, 6):  # Terminal prompts
            pylogger.debug("Passwordless access enabled for %r" % self.ip)
        else:
            pylogger.error(err_msg % (self.ip, self.username))
            pylogger.error("Pexpect Before: %r" % self.pexpectconn.before)
            pylogger.error("Pexpect After: %r" % self.pexpectconn.after)
            raise RuntimeError(err_msg % (self.ip, self.username))
        self.anchor = self.pexpectconn

    def login_to_st_en_terminal(self, expect=""):
        """ This method allow to login to st en terminal on NSX Manager
            and allow command execution on root prompt.

            @param expect="" expected prompt
            @param root_password="" password to login to st en prompt.This
            password taken from testbedspec file. If not password provided
            then default password is "default"

            Sequence of command execution:
            1. User already logged in to NSX Manager.
            2. Enter "st en", this will prompt for "Password:"
            3. Provide password and Enter.
            4. User will be on root prompt.
        """

        if self.root_password == "" or self.root_password is None:
            self.root_password = "default"

        self.default_prompt(command='st e', expect=['Password:'])
        self.default_prompt(command=self.root_password, expect=expect)

    def logout_of_st_en_terminal(self):
        """
        Logout of 'st en' mode on a device.

        E.g.:
            [root@nimbus-cloud-nsxmanager ~]# exit
            logout

            nimbus-cloud-nsxmanager>
        """
        self.default_prompt(command='exit', expect=['bytes*', '>'])

    def execute_command_in_configure_terminal(self, command="", expect="",
                                              enable_password="", strict=True,
                                              expect_logout_prompt=""):
        """ Executes the command using the expect connection in the configure
         terminal after execution of command it will exit from configure mode.

        @param expect="" expected prompt
        @param command="" command to be executed
        @param enable_password"" password to login to the enable prompt
        @param expect_logout_prompt"" expect logout prompt from config terminal

        @return cli command output, pexpect response

        Here is a typical sequence to execute something in configure terminal
        mode:
            1. Enter 'configure terminal' on the prompt.
            2. Enter the command to be executed in 'configure terminal' mode.
            3. Exit out of 'configure terminal' mode using 'exit' command.
        """
        # Set the configure terminal
        self.login_to_configure_terminal(enable_password=enable_password,
                                         expect=expect)

        # Execute the command
        pylogger.debug("Executing command %r on %r" % (command, self.ip))
        pylogger.debug("Expecting prompt %s " % expect)
        self.pexpectconn.sendline(command)
        pexpect_response = self.pexpectconn.expect(expect)
        command_output = self.pexpectconn.before
        pylogger.info("Command Output %s : %s" % (command, command_output))

        # exit from config terminal
        if expect_logout_prompt != "":
            self.logout_from_configure_terminal(expect=expect_logout_prompt)
        else:
            self.logout_from_configure_terminal(expect=expect)
        return pexpect_response, command_output

    def login_to_configure_terminal(self, enable_password="", expect=""):
        """
        Login to the 'configure terminal' mode for a given device.

        E.g.:
            NSXEdge> configure terminal
            NSXEdge(config)#
        """
        self.default_prompt(command='configure terminal',
                            expect=['\(config\)#'])

    def logout_from_configure_terminal(self, expect=""):
        """
        Logout of 'configure terminal' mode on a device.

        E.g.:
            NSXEdge(config)# exit
            NSXEdge#
        """
        self.default_prompt(command='exit', expect=expect)

    def request(self, command="", expect="", control="", wait="", strict=True,
                timeout=None):
        """ Execute the command using the expect connection,

        @param Comply with parent method signature by returning response
            object as
        parent query() read() etc will use this request method
        @return cli response object which is stdout object obtained from
            expect() command

        @param control: key required with 'Ctrl+<key>' to terminate/end
        @param wait: wait for given time to collect sizable data e.g. ping IP
        """
        if timeout is None:
            timeout = constants.Timeout.DEFAULT_EXPECT_REQUEST_TIMEOUT

        pylogger.debug("Executing command %s " % command)
        pylogger.debug("Expecting prompt %s " % expect)
        response = self.read_until_prompt(expect=expect, command=command,
                                          control=control, wait=wait,
                                          strict=strict, timeout=timeout)
        return response

    def default_prompt(self, command="", expect="", timeout=30):
        try:
            temp, self.pexpectconn.timeout = self.pexpectconn.timeout, timeout
            self.pexpectconn.sendline(command)
            return self.pexpectconn.expect(expect)
        finally:
            self.pexpectconn.timeout = temp

    def read_until_prompt(self, expect="", command="", control="", wait="",
                          strict=None, timeout=30):
        """
        This function is use to read all the commandline output until the
        byte prompt(i.e byte *) is displayed, and will exit the prompt after
        the vshield edge prompt (i.e >) is displayed. The output is generated
        in a text file which is processed so as to removed the
        Enter/Space/ControlM characters from the output.

        @param expect="" expected prompt
        @param command="" command to be executed
        @param control="" key required for 'Ctrl+<key>' to terminate/end
        @param wait="" wait for given time to collect sizable data e.g. ping IP

        @return returns the result object with response_data, stderr and exit
            code.
        """

        temp = self.pexpectconn.timeout
        self.pexpectconn.timeout = timeout
        lines = None
        ret = result.Result()
        pexpect_outfile = tempfile.NamedTemporaryFile(
            suffix="_cli_output", delete=False)
        pexpect_outfilename = pexpect_outfile.name
        pylogger.debug("Pexpect Output Temporary File Name = %s" %
                       pexpect_outfilename)
        processed_outfile = tempfile.NamedTemporaryFile(
            suffix="_processed_cli_output", delete=False)
        processed_outfilename = processed_outfile.name
        pylogger.debug("Processed outfile Temporary File Name = %s" %
                       processed_outfilename)
        self.pexpectconn.sendline(command)

        if wait:
            pylogger.debug("Waiting for [%d] seconds." % wait)
            time.sleep(wait)

        if control:
            pylogger.debug("Sending [Ctrl + %s] command." % control)
            self.pexpectconn.sendcontrol(control)

        if expect:
            expect_condition = self.pexpectconn.expect(expect)
            pylogger.debug("Expect_Condition value = %d" % expect_condition)
            while expect_condition == self.NEXT_PAGE_PROMPT:
                pexpect_outfile.writelines(
                    self.pexpectconn.before.strip())
                self.pexpectconn.sendline(' ')
                expect_condition = self.pexpectconn.expect(expect)
            if expect_condition == self.EXPECT_PROMPT:
                pexpect_outfile.writelines(
                    self.pexpectconn.before.strip())
        pexpect_outfile.close()
        # sed file operation.
        # The regex replaces the special characters returned in the CLI output
        # to the UTF characters.
        sed_cmd = (
            'cat -vT %s | sed "s/\^M//g"  |  sed "s/\^I/ /g"  | '
            'sed "s/\(^\^\[.*\[\[K\)\(.*\)/\\2/g" | '
            'sed "s/\(^\^.*[=]\)\(.*\)/\\2/g" | '
            'sed "s/^\^.*//g" > %s' %
            (pexpect_outfilename, processed_outfilename))
        exit_code, stdout, stderr = compute_utilities.run_command_sync(sed_cmd)
        self.pexpectconn.timeout = temp
        if stdout:
            pylogger.debug('STDOUT: %r' % stdout)
        if stderr:
            pylogger.debug('SDTDERR: %r' % stderr)
        pylogger.debug("Removing the pexpect_out file %s" %
                       pexpect_outfilename)
        os.remove(pexpect_outfilename)
        if exit_code:
            pylogger.warn('Removing special characters from the received '
                          'pexpect text failed with error code: %r' %
                          exit_code)
            if strict:
                raise RuntimeError('Execution of %r errored out with exit '
                                   'code %r' % (sed_cmd, exit_code))
        else:
            # read the file
            readfile_handle = open(processed_outfilename, "r")
            lines = readfile_handle.readlines()
            readfile_handle.close()
            for line in lines:
                if line:
                    pylogger.debug("Pexpect Output: %s" % line)
            lines = ''.join(lines)
            if lines and lines[0] in err_chars and strict:
                failure_msg = ("Pexpect command: %r failed with error: %r"
                               % (command, lines[1:]))
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=failure_msg)
            pylogger.debug("Removing the processed file %r" %
                           processed_outfilename)
            os.remove(processed_outfilename)
        ret.response_data = lines
        ret.error = stderr
        ret.status_code = exit_code
        return ret

    def close(self):
        """
        Closes the pexpect session.
        """
        self.anchor.close()

    def execute_command_with_hostkey_prompt(
            self, command="", remote_password="", final_expect=None):
        if final_expect is None:
            final_expect = self.terminal_prompts

        pylogger.debug("Executing command %r " % command)
        err_msg = "Failed to execute command %r"

        # Ordering is checked in the following specific order,
        # 1. Continuity steps for host key/password prompts
        # 2. Erroneous checks like EOF/Timeout
        # 3. Final expect prompt check
        expect = ([pexpect.TIMEOUT, pexpect.EOF, HOSTKEY_PROMPT] +
                  PASSWORD_PROMPTS + final_expect)
        pexpect_status = self.default_prompt(command=command, expect=expect)
        if pexpect_status == 2:  # ssh host key check
            pexpect_status = self.default_prompt(command="yes", expect=expect)
        if pexpect_status in (3, 4):  # Password prompt
            pexpect_status = self.default_prompt(
                command=remote_password, expect=expect)
        if pexpect_status == 0:  # Timeout
            err_msg = "Pexpect timed out while executing %r"
        if pexpect_status == 1:  # EOF found
            err_msg = "Pexpect received EOF while executing %r"
        if pexpect_status >= 5:  # Final expect prompt
            pylogger.debug("Executed command %r successfully" % command)
        else:
            pylogger.error(err_msg % command)
            pylogger.error("Pexpect Before: %r" % self.pexpectconn.before)
            pylogger.error("Pexpect After: %r" % self.pexpectconn.after)
            raise RuntimeError(err_msg % command)
        self.close()

    def execute_command_in_enable_terminal(self, command="", expect="",
                                           password="", strict=True):
        """ Executes the command using the expect connection in the enable
         terminal using the provided password; after execution of command
         it will exit from configure mode.

        @param expect="" expected prompt
        @param command="" command to be executed

        @return cli command output, pexpect response
        """
        if password == "":
            password = constants.VSMterms.PASSWORD

        # Set the configure terminal
        self.default_prompt('enable', ['Password:'])
        self.default_prompt(password, ['#'])

        # Execute the command
        pylogger.debug("Executing command %s " % command)
        pylogger.debug("Expecting prompt %s " % expect)
        self.pexpectconn.sendline(command)
        pexpect_response = self.pexpectconn.expect(expect)
        command_output = self.pexpectconn.before
        pylogger.info("Command Output %s : %s" % (command, command_output))

        return pexpect_response, command_output

if __name__ == '__main__':
    e = ExpectConnection("10.117.81.85", "admin", "default")
    e.create_connection()
    output = e.read_until_prompt(['bytes*', '>'], "show arp").response_data
    print "Myoutput = %s" % output
