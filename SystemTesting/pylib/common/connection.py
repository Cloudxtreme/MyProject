import httplib
import os.path
import re
import pexpect
import paramiko
import socket
import ssl
from expect_connection import ExpectConnection
from ssh_connection import SSHConnection
import vmware.common.global_config as global_config

class Connection:
    """ Class to create connection and request and get response
    for queries
    """

    def __init__(self):
        """ Constructor to create an instance of Connection class
        """

        self.log = global_config.pylogger
        self.ip =  None
        self.username = None
        self.password = None
        self.auth_token = None
        self.type = None
        self.api_header = None
        self.anchor = None

    def __init__(self, ip, username, password, api_header, type="http"):
        self.log = global_config.pylogger
        self.ip = ip
        self.username = username
        self.password = password
        self.type = type
        self.api_header = api_header
        self.log.debug("connecting to :" + self.ip)
        self.anchor = self.createConnection()

    def set_api_header(self, api_header):
        """ Method to set api_header attribute

        @param api_header api header value
        """

        self.api_header = api_header

    def createConnection(self):
        """ Method to create connection

        @return httplib connection object
        """

        conn = ""
        context = ssl._create_unverified_context()
        if self.type == "https":
            conn = httplib.HTTPSConnection(self.ip, context=context)
            sock = socket.create_connection(
               (conn.host, conn.port), conn.timeout, conn.source_address)
            conn.sock = ssl.wrap_socket(sock, conn.key_file, conn.cert_file,
                                        ssl_version=ssl.PROTOCOL_TLSv1)
        elif self.type == "ssh":
            conn = SSHConnection(self.ip, self.username, self.password)
        elif self.type == "scp":
            transport = paramiko.Transport((self.ip, 22))
            transport.connect(username="root", password=self.password)
            conn = paramiko.SFTPClient.from_transport(transport)
        elif self.type == "expect":
            conn = ExpectConnection(self.ip, self.username, self.password)
        else:
            conn = httplib.HTTPConnection(self.ip)
        return conn

    def request(self, method, url, payload, headers):
        """ Method to make request call

        @param method   method name
        @param url      url or endpoint value
        @param payload  request payload
        @param headers  http header value
        @return http response object
        """
        ssl._create_default_https_context = ssl._create_unverified_context
        self.anchor.request(method, url, payload, headers)
        self.log.debug("Request call: %s://%s%s" % (self.type, self.ip, url))
        self.log.debug("Request payload: %s" % payload)
        response = self.anchor.getresponse()
        self.log.debug("Response status %s" % response.status)
        if response.reason:
            self.log.debug("Reason %s" % response.reason)
        return response

if __name__ == '__main__':
    ssh_connection = Connection("10.24.20.31", "root", "ca$hc0w", "None", "ssh")
    #ssh_connection.generate_rsa_keys()
    #ssh_connection.get_rsa_public_key()
    #ssh_connection.enable_passwordless_access()
