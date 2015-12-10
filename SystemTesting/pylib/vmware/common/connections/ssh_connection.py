import logging
import paramiko
import re

import vmware.common.compute_utilities as compute_utilities
import vmware.common.connection as connection
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.result as result
import vmware.common.utilities as utilities

CONNECTION_TIMEOUT = constants.Timeout.SSH_CONNECT
COMMAND_EXEC_TIMEOUT = global_config.COMMAND_EXEC_TIMEOUT

pylogger = global_config.pylogger

if pylogger is None:
    pylogger = global_config.configure_logger(
        log_prefix="SSHConnection", stdout=True, log_level=logging.INFO,
        logfile_level=logging.DEBUG)


class SSHConnection(connection.Connection):

    def __init__(self, ip="", username="", password="",
                 connection_object=None):
        super(SSHConnection, self).__init__(ip, username, password,
                                            connection_object)

    def create_connection(self):
        conn = paramiko.SSHClient()
        conn.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        host_keys_file = global_config.get_host_keys_file()
        pylogger.debug("Loading ssh known_hosts key from %r" % host_keys_file)
        conn.load_host_keys(host_keys_file)
        try:
            conn.connect(self.ip,
                         username=self.username,
                         password=self.password,
                         timeout=CONNECTION_TIMEOUT)
        except paramiko.ssh_exception.AuthenticationException:
            pylogger.debug(("Connection failed with IP: %s, username: %s, "
                            "password: %s") %
                           (self.ip, self.username, self.password))
            pylogger.exception("Authentication failed!")
            raise
        except Exception:
            pylogger.exception("Connection to IP: %r (%r/%r) failed due to "
                               "unknown reason!" % (self.ip, self.username,
                                                    self.password))
            raise
        self.anchor = conn

    def request(self, command, strict=True, timeout=None,
                wait_for_reboot=None, reboot_timeout=None):
        """
        Method for passing on request over SSH to the remote host.

        @param command: Command to be executed on the remote host.
        @type command: str
        @param strict: When set, method will raise an exception if the command
            executed on the host hasn't succeeded. The raising of exception is
            made optional so as to facilitate negative testing.
        @type wait_for_reboot: bool
        @param wait_for_reboot: Parameter to indicate that a command is going
            to reboot the system, when that happens paramiko will wait till the
            host reboots and will recreate a new session to the host so that
            next executed command doesn't fail.
        @type reboot_timeout: int
        @param reboot_timeout: Seconds to wait before timing out the wait on
            the rebooting host.
        @rtype: result.Result
        @return: Returns a result object that contains status_code, error,
            reason and response_data
        """
        print "command before stripping: %s" % command
        command = command.strip('\n');
        print "command after stripping: %s" % command
        reboot_timeout = utilities.get_default(
            reboot_timeout, constants.Timeout.HOST_REBOOT_MAX)
        timeout = utilities.get_default(timeout, COMMAND_EXEC_TIMEOUT)
        pylogger.debug("Executing command %r on %r with timeout of %r "
                       "seconds" % (command, self.ip, timeout))
        print "Executing command %r on %r with timeout of %r seconds" % (command, self.ip, timeout)
        print "Executing command s %s on %s with timeout of %s seconds" % (repr(command), self.ip, timeout)
        if command == "esxcli network nic DOWN -n vmnic1":
            command = command.lower()
            command = "/bin/"+command
            stdin, stdout, stderr = self.anchor.exec_command(str(command))
        else:
            stdin, stdout, stderr = self.anchor.exec_command(command)
#        stdin, stdout, stderr = self.anchor.exec_command("""esxcli network nic up -n vmnic3""")
        stdin.flush()
        stdin.channel.shutdown_write()
        stdout.channel.settimeout(timeout)
        stderr.channel.settimeout(timeout)
        stderr_lines = stderr.read()
        stdout_lines = stdout.read()
        # All returned objects contain the same status code.
        status_code = stdout.channel.recv_exit_status()
        for line in stdout_lines.splitlines():
            pylogger.debug("Stdout: %r" % line)
        for line in stderr_lines.splitlines():
            if line:
                logger = (pylogger.error if status_code and strict else
                          pylogger.debug)
                logger("Stderr: %r" % line)
        if strict and status_code:
            raise RuntimeError(
                'SSH command error: Host=%r, command=%r, exitcode=%r, '
                'stdout=%r, stderr=%r' % (self.ip, command, status_code,
                                          stdout_lines, stderr_lines))
        ret = result.Result()
        ret.response_data = stdout_lines
        ret.error = stderr_lines
        ret.status_code = status_code
        if wait_for_reboot:
            self.close()
            reboot_completed = compute_utilities.wait_for_ip_reachable(
                self.ip, timeout=reboot_timeout)
            if not reboot_completed:
                raise AssertionError("Waited %r seconds for %r to come back "
                                     "up but failed" % (reboot_timeout,
                                                        self.ip))
                self.create_connection()
        return ret

    def close(self):
        """ close ssh connection"""
        self.anchor.close()

    def enable_passwordless_access(self):
        """ Method to make request call

        """
        # Workflow
        # Check if your public key exists
        # If yes not need to create, else create it
        # Copy the public key to remote machine for passwordless acess

        public_key = self.get_rsa_public_key()
        if re.search('ssh-rsa', public_key) is None:
            self.generate_rsa_keys()
            public_key = self.get_rsa_public_key()

        # Copy the public key to the remote server
        stdin, stdout, stderr = self.anchor.exec_command('echo $HOME')
        remote_home = stdout.read().strip()
        sftp = self.anchor.open_sftp()
        try:
            sftp.mkdir(remote_home + '/.ssh')
        except IOError:
            pass
        remote_authorized_keys_file = "%s%s" % \
            (remote_home, '/.ssh/authorized_keys')
        remote_file_handle = sftp.open(remote_authorized_keys_file, 'a+')
        if re.search(re.escape(public_key), remote_file_handle.read()) is None:
            pylogger.debug("Public key copied to remote machine")
            remote_file_handle.write(public_key)
        else:
            pylogger.debug("Public keys %s exists on remote machine" %
                           (remote_authorized_keys_file))
        remote_file_handle.close()

    def generate_rsa_keys(self):
        """ Method to make request call

        @return http response object
        """
        command = 'echo -e  \'y\n\'' \
                  '|ssh-keygen -q -t rsa -N \"\" -f ~/.ssh/id_rsa'
        (output, stdout, stderr) = compute_utilities.run_command_sync(command)
        pylogger.debug('generate_rsa_keys stdout: %s\n \
                       stderr:%s\n output:%s' % (stdout, stderr, output))

    def get_rsa_public_key(self):
        """ Method to make request call

        @return http response object
        """
        command = 'echo  \'\'|ssh-keygen -y'
        (output, stdout, stderr) = compute_utilities.run_command_sync(command)
        pylogger.debug('get_rsa_public_key stdout: %s\n \
                       stderr:%s\n output:%s' % (stdout, stderr, output))
        return stdout

    def remove_outdated_ssh_fingerprint(self, remove_host):
        """ Method to remove outdated ssh fingerprint for given host

        @return http response object
        """
        command = '%s %s' % ('ssh-keygen -R', remove_host)
        (output, stdout, stderr) = compute_utilities.run_command_sync(command)
        pylogger.debug('remove_outdated_ssh_fingerprint stdout: %s\n \
                       stderr:%s\n output:%s' % (stdout, stderr, output))

if __name__ == "__main__":
    conn = SSHConnection(ip='127.0.0.1', username='root', password='ca$hc0w')
    conn.create_connection()
    print conn.request('ls').response_data
