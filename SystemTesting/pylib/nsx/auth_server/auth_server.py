import base_client
import connection
from base_cli_client import BaseCLIClient


class AuthServer(base_client.BaseClient):
    ''' Class to store attributes and methods for AuthServer '''

    def __init__(self, ip, user, password):
        ''' Constructor to create an instance of AuthServer class
        @param ip:  ip address of AuthServer
        @param user: user name of AuthServer
        @param password: password of AuthServer
        '''

        super(AuthServer, self).__init__()
        self.ip = ip
        self.username = user
        self.password = password
        self.ssh_connection = None

    def execute_command(self, command):
        """ Method to execute simple command on Authentication Server"""
        cli = BaseCLIClient()
        cli.set_schema_class('no_stdout_schema.NoStdOutSchema')
        cli.set_create_endpoint(command)
        ssh = self.get_ssh_connection()
        cli.set_connection(ssh)
        cli_data = cli.read()
        self.log.debug("CLI Data: %s" % cli_data)
        ssh.close()
        return "SUCCESS"

    def get_ssh_connection(self):
        ssh_connection = connection.Connection(self.ip, self.username, self.password, "None", "ssh")
        self.ssh_connection = ssh_connection.anchor
        return self.ssh_connection

if __name__ == '__main__':
    pass
