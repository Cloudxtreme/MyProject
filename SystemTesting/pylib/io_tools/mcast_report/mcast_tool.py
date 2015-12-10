#!/usr/bin/env python
#
# Works in client/server mode, server will accept command from client
# and find calling instructions to use the APIs in mcast_report.py to
# send multicast report messages. The calling instructions may be stored
# in a local file or from socket, it may look like below,
# cat mcast_tasks_ipv6.conf
# [mcast_task1]
# method = MCAST_JOIN_GROUP
# interface = eth0
# family=ipv6
# group_address = ff39::1:1
#
# [mcast_task2]
# method = MCAST_BLOCK_SOURCE
# interface = eth0
# family=ipv6
# group_address = ff39::1:1
# source_addr_array = 2002::1:1; 2002::1:2
#
# To start server: mcast_tool.py -s [-H ip] [-p port]
# To start client: mcast_tool.py -c -t -f mcast_task.conf [-H ip] [-p port]
#             or  mcast_tool.py -c -f mcast_task.conf [-H ip] [-p port]'
#
# Command sent from client to server may be 'FILENAME', 'STREAM', 'QUIT'
# 'FILENAME', instruct server to read instructions from local file in
# server side. Format, 'FILENAME:filename'
# 'STREAM', instruct server to read instructions from socket, Format,
# 'STREAM:file content'
# 'QUIT', instruct server to quit.
#
# Response message from server: may be 'SUCCESS:sucess_msg',
# 'FAILURE:failure_msg'
# client will print out the response message to stdout. In vdnet, we may
# launch server in async mode, and launch client in sync mode, decide the
# result for checking stdout of client.
#
################################################################################

import sys
import getopt
import select
import socket
import time
import re
import ConfigParser
import io
import os
from mcast_report import *

'''Commands sent from client to host'''
FILENAME = 'FILENAME'
STREAM = 'STREAM'
QUIT = 'QUIT'

'''Response code from server to client
Format is RESCODE:MESSAGE
'''
SUCCESS = 'SUCCESS'
FAILURE = 'FAILURE'

'''TIMEOUT to indict a receive timeout'''
TIMEOUT = 'TIMEOUT'
timeout_val = 30

'''end marker for payload'''
END_MARKER = '@@'

RECV_BUFSIZE = 1024
READ_FILESIZE = 65536
DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORT = 50007

class McastTestSocket():
    ''' Class provide apis for server/client communication through socket
    '''

    def __init__(self, host, port, end_marker=END_MARKER):
        '''
        @param end_marker, end marker of payload
        '''

        self.end_marker = end_marker
        self.host = host
        self.port = port
        self.sock_obj = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock_obj.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.trans_sock = None

    def bind_listen(self):
        ''' used for server to bind and listen
        '''
        try:
           self.sock_obj.bind((self.host, self.port))
           self.sock_obj.listen(1)
        except socket.error, msg:
           print 'Error while trying to bind and listen on host %s port %d' % \
                                                     (self.host, self.port)
           print msg
           sys.exit(1)

    def accept(self):
        ''' used for server to accept a connection
        '''
        try:
           self.conn, self.addr = self.sock_obj.accept()
           self.trans_sock = self.conn
        except socket.error, msg:
           print 'Error while calling accept'
           print msg
           sys.exit(1)

    def connect(self):
        ''' used for client to connect to server
        '''
        try:
           self.sock_obj.connect((self.host, self.port))
           self.trans_sock = self.sock_obj
        except socket.error, msg:
           print 'Error while trying to connect to host %s port %d' % \
                                                 (self.host, self.port)
           print msg
           sys.exit(1)

    def recv_end(self, timeout):
        total_data = [];
        data = ''
        while True:
            inputs = [self.trans_sock]
            readable , writable , exceptional = \
                select.select(inputs, [], [], timeout)
            if self.trans_sock not in readable:
                print 'select TIMEOUT reached!'
                return TIMEOUT
            data = self.trans_sock.recv(RECV_BUFSIZE)
            if not data:
                print 'Connect lost or timeout reached!'
                return TIMEOUT
            if self.end_marker in data:
                total_data.append(data[:data.find(self.end_marker)])
                break
            total_data.append(data)
            if len(total_data) > 1:
                ''' check if end_of_data was split '''
                last_pair = total_data[-2] + total_data[-1]
                if self.end_marker in last_pair:
                    total_data[-2] = \
                        last_pair[:last_pair.find(self.end_marker)]
                    total_data.pop()
                    break
        return ''.join(total_data)

    def send_end(self, data):
        self.trans_sock.sendall(data + self.end_marker)

    def send_file(self, filename):
        ''' transport content of file to network

        @param filename, file name
        '''
        conf_file = open(filename, 'rb')
        while True:
            ''' Read content of config file, thinking the size of
            config file is usually small, use 65536 (READ_FILESIZE)
            trying to read all content one time.
            '''
            chunk = conf_file.read(READ_FILESIZE)
            if not chunk:
                ''' EOF '''
                break
            self.trans_sock.sendall(chunk)
        self.trans_sock.sendall(self.end_marker)

    def close(self):
        self.trans_sock.close()


class McastTestServer():
    ''' Class acting as multicast test server
    '''

    def __init__(self, host, port):
        '''
        @param end_marker, end marker of payload
        '''

        self.serv_socket = McastTestSocket(host, port)
        self.success = SUCCESS
        self.failure = FAILURE
        self.result = None
        self.result_msg = None
        self.ipv4_mcast_obj = MulticastReport(socket.AF_INET)
        self.ipv6_mcast_obj = MulticastReport(socket.AF_INET6)
        self.serv_socket.bind_listen()
        self.config_parser = ConfigParser.RawConfigParser(allow_no_value=True)

    def end(self):
        self.serv_socket.close()

    def server_accept(self):
        self.data = self.serv_socket.accept()

    def server_recv(self, timeout=None):
        self.data = self.serv_socket.recv_end(timeout)

    def server_reply(self):
        if (self.result != None):
            send_data = '%s:%s' % (self.result, self.result_msg)
            self.serv_socket.send_end(send_data)

    def server_parse_data(self):
        ''' Parse the command sent from client
        Command may be
        FILENAME - instruct server to read local file on sever side and call
                    multicast report method accordingly defined in the file.
        STREAM   - instruct server to read instructions from socket side and call
                    multicast report method accordingly
        QUIT     - instruct server to quit.
        '''

        matchObj = re.match(r'(.*):(.*)', self.data)
        if matchObj is None:
            self.result = self.failure
            self.result_msg = 'Regular expression parse error.'
            return False

        if matchObj.group(1) == FILENAME:
            filename = matchObj.group(2)
            if not os.path.exists(filename):
                self.result = FAILURE
                self.result_msg = \
                    'Failed to find file (%s) on server' % (filename)
                return False
            self.read_from_file(filename)
        elif matchObj.group(1) == STREAM:
            self.read_from_stream()
        elif matchObj.group(1) == QUIT:
            self.result = SUCCESS
            self.result_msg = "QUIT"
            self.server_reply()
            self.serv_socket.close()
            sys.exit(0)
        else:
            self.result = self.failure
            self.result_msg = 'Invalid control cmd: %s' % (matchObj.group(1))
            return False

    def read_from_stream(self):
        self.server_recv(timeout=timeout_val)
        if (self.data == TIMEOUT):
            self.result = self.failure
            self.result_msg = 'Timeout occurred while reading read stream'
            return False
        self.config_parser.readfp(io.BytesIO(self.data))
        return self.call_mcast_report()

    def read_from_file(self, filename):
        self.config_parser.read(filename)
        return self.call_mcast_report()

    def call_mcast_report(self):
        result = True
        multicast_dict = {}
        for section in self.config_parser.sections():
            section_dict = self.config_section_map(section)
            for option in ['method', 'interface', 'family', 'group_address']:
                if (not section_dict.has_key(option)):
                    self.result = self.failure
                    self.result_msg = \
                            'Option (%s) was not found in file' % (option)
                    return False
                else:
                    multicast_dict[option] = section_dict[option]
            if (section_dict.has_key('source_addr_array')):
                sources = section_dict['source_addr_array']
                multicast_dict['source_addr_array'] = sources.replace(' ', '').split(';')
            result &= self.do_mcast_report(multicast_dict)
        return result

    def do_mcast_report(self, multicast_dict):
        ''' call mutlicast method defined in file or from socket stream
        '''
        if (multicast_dict['family'] == 'ipv6'):
            mcast_obj = self.ipv6_mcast_obj
        else:
            mcast_obj = self.ipv4_mcast_obj

        try:
            mcast_obj.set_multicast_params(multicast_dict)
            ''' call the mulicast method in MulticastReport obj'''
            getattr(mcast_obj, multicast_dict['method'])()
        except socket.error, msg:
            message = 'Failed while calling method (%s),%s' % \
                (multicast_dict['method'], msg)
            self.result = self.failure
            self.result_msg = message
            return False

        self.result = self.success
        self.result_msg = 'Succeeded to execute method %s' % \
            multicast_dict['method']
        return True;

    def run(self):
        while True:
            self.server_accept()
            self.server_recv()
            self.server_parse_data()
            self.server_reply()

    def config_section_map(self, section):
        dict1 = {}
        options = self.config_parser.options(section)
        for option in options:
            try:
                dict1[option] = self.config_parser.get(section, option)
                if dict1[option] == -1:
                    print('skip: %s' % option)
            except:
                print('exception on %s!' % option)
                dict1[option] = None
        return dict1

class McastTestClient():
    ''' Class acting as multicast test client
    '''

    def __init__(self, host, port, filename, stream, quit):
        self.client_socket = McastTestSocket(host, port)
        self.filename = filename
        self.stream = stream
        self.quit = quit

    def run(self):
        self.client_socket.connect()
        if self.quit == True:
            self.client_socket.send_end('%s:' % QUIT)
        else:
            if self.filename is None:
                 print 'need filename parameter'
                 sys.exit(1);
            if self.stream != True:
                self.client_socket.send_end('%s:%s' % (FILENAME, self.filename))
            else:
                if not os.path.exists(self.filename):
                    result = FAILURE
                    result_msg = 'Failed to find file (%s) on client' % \
                        (self.filename)
                    print '%s:%s' % (result, result_msg)
                    self.client_socket.close()
                    sys.exit(1)

                self.client_socket.send_end('%s:' % STREAM)
                self.client_socket.send_file(self.filename)

        ''' waiting response (method execution result) from server,
        add timeout to avoid the client to hang forever
        '''
        exit_code = 0
        data = self.client_socket.recv_end(timeout=timeout_val)
        if (data == TIMEOUT):
            result = FAILURE
            result_msg = 'Timeout occurred while receiving data from server!'
        else:
            matchObj = re.match(r'(.*):(.*)', data)
            result = matchObj.group(1)
            result_msg = matchObj.group(2)

        if (result != SUCCESS):
            exit_code = 1
        print '%s:%s' % (result, result_msg)
        self.client_socket.close()
        sys.exit(exit_code)

def print_help():
    print 'To start server: mcast_test.py -s [-H ip] [-p port]'
    print 'To start client in STREAM mode, config file need to be ' + \
                                       'accessable on client side:'
    print '   mcast_test.py -c -t -f mcast_task.conf [-H ip] [-p port]'
    print 'Or to start client in FILE mode, config file need to be ' + \
                                       'accessable on server side:'
    print '   mcast_test.py -c -f mcast_task.conf [-H ip] [-p port]'
    print 'To let server quit:'
    print '   mcast_test.py -c -q [-H ip] [-p port]'

def main():
    '''
    server: mcast_test.py -s
    client: mcast_test.py -c -t -f mcast_task1.conf, which will
                    instruct server to read method instruction
                    from network
    client: mcast_test.py -c -f mcast_task1.conf, which will
                    instruct server to read method instruction
                    from local file on server side
    sample file, mcast_task1.conf,
    # cat mcast_task.conf
    [mcast_task1]
    method = MCAST_JOIN_GROUP
    interface = eth0
    family=ipv4
    group_address = 239.1.1.2

    [mcast_task2]
    method = MCAST_BLOCK_SOURCE
    interface = eth0
    family=ipv4
    group_address = 239.1.1.2
    source_addr_array = 192.168.1.1, 192.168.1.2
    '''
    mode = None
    end_marker = END_MARKER
    host = DEFAULT_HOST
    port = DEFAULT_PORT
    try:
        opts, args = getopt.getopt(sys.argv[1:],
                'f:H:p:shcqt', ['file=', 'host=', 'port=', 'help'])
    except getopt.GetoptError, err:
        print str(err)
        print_help()
        sys.exit(1)
    filename = None
    stream = False
    quit = False
    for opt, append in opts:
        if opt == '-s':
            mode = 's'
        elif opt == '-c':
            mode = 'c'
        elif opt in ('-h', '--help'):
            print_help()
            sys.exit(0)
        elif opt in ('-f', '--file'):
            filename = append
        elif opt in ('-H', '--host'):
            host = append
        elif opt in ('-p', '--port'):
            port = int(append)
        elif opt == '-t':
            stream = True
        elif opt == '-q':
            quit = True

    if mode == 's':
        # start server
        server = McastTestServer(host, port)
        server.run()
    elif mode == 'c':
        # start client
        client =  McastTestClient(host, port, filename, stream, quit)
        client.run()

if __name__ == '__main__':
    main()
