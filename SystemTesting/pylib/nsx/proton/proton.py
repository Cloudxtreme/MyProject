import base_client
import connection
from base_cli_client import BaseCLIClient

class Proton(base_client.BaseClient):
   ''' Class to store attributes and methods for NSX '''

   def __init__(self, ip, user, password, version=None):
      ''' Constructor to create an instanc of VSM class

      @param ip:  ip address of NSX
      @param user: user name to create connection
      @param password: password to create connection
      '''

      super(Proton, self).__init__()
      self.ip = ip
      self.username = user
      self.password = password
      self.ssh_connection = None

   def execute_bash_command(self, command):
      """ Method to execute simple command on Proton Server"""
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
