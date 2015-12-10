import pexpect
import vmware.common.logger as logger
import paramiko
import re
import os.path
import utility
from vmware.common.global_config import pylogger


class SSHConnection:
    """ Class to create ssh connection and request and get response
    for queries
    """

    def __init__(self, ip, username, password):
        self.ip = ip
        self.username = username
        self.password = password
        conn = paramiko.SSHClient()
        conn.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        # In case the server's key is unknown,
        # we will be adding it automatically to the list of known hosts
        # Remove stale host key for this ip
        self.remove_outdated_ssh_fingerprint(self.ip)
        conn.load_host_keys(os.path.expanduser(os.path.join("~", ".ssh", "known_hosts")))
        conn.connect(self.ip, username = self.username, password = self.password)
        self.sshconn = conn

    def request(self, command):
        """ Method to execute a ssh command

        @param command  command to be executed
        @param headers  http header value
        @return stdin   stdin of the command
        @return stdout  stdout of the command
        @return stderr  stderr of the command
        """

        stdin, stdout, stderr = self.sshconn.exec_command(command)
        return stdin, stdout, stderr

    def close(self):
        """ close ssh connection"""
        self.sshconn.close()

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
        stdin, stdout, stderr = self.sshconn.exec_command('echo $HOME')
        remote_home = stdout.read().strip()
        sftp = self.sshconn.open_sftp()
        try:
            sftp.mkdir(remote_home + '/.ssh')
        except IOError:
            pass
        remote_authorized_keys_file = "%s%s" % (remote_home, '/.ssh/authorized_keys')
        remote_file_handle = sftp.open(remote_authorized_keys_file, 'a+')
        if re.search(public_key, remote_file_handle.read()) is None:
            pylogger.debug("Public key copied to remote machine")
            remote_file_handle.write(public_key)
        else:
            pylogger.debug("Public keys already exists in %s on remote machine" % (remote_authorized_keys_file))
        remote_file_handle.close()

    def generate_rsa_keys(self):
        """ Method to make request call

        @return http response object
        """
        command = 'echo -e  \'y\n\'|ssh-keygen -q -t rsa -N \"\" -f ~/.ssh/id_rsa'
        (output, stdout, stderr) = utility.run_command_sync(command)
        pylogger.debug('generate_rsa_keys stdout: %s\n \
                       stderr:%s\n output:%s' % (stdout, stderr, output))

    def get_rsa_public_key(self):
        """ Method to make request call

        @return http response object
        """
        command = 'echo  \'\'|ssh-keygen -y'
        (output, stdout, stderr) = utility.run_command_sync(command)
        pylogger.debug('get_rsa_public_key stdout: %s\n \
                       stderr:%s\n output:%s' % (stdout, stderr, output))
        return stdout

    def remove_outdated_ssh_fingerprint(self, remove_host):
        """ Method to remove outdated ssh fingerprint for given host

        @return http response object
        """
        command = '%s %s' % ('ssh-keygen -R', remove_host)
        (output, stdout, stderr) = utility.run_command_sync(command)
        pylogger.debug('remove_outdated_ssh_fingerprint stdout: %s\n \
                       stderr:%s\n output:%s' % (stdout, stderr, output))

