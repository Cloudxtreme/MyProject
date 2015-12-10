#!/usr/bin/env python
#
# This file provides method to send multicast report messages in
# a 32-bit or 64-bit Linux VM. The report message may be IGMP
# (Internet Group Management Protocol) packets for IPv4 or MLD
# (Multicast Listener Discovery) packets for IPv6. Tcpdump may be
# used to monitor the packets sent by this tool.
#
# Following types of multicast report messages may be sent by this
# tool,
#        MCAST_JOIN_GROUP,
#        MCAST_BLOCK_SOURCE,
#        MCAST_UNBLOCK_SOURCE,
#        MCAST_LEAVE_GROUP,
#        MCAST_JOIN_SOURCE_GROUP,
#        MCAST_LEAVE_SOURCE_GROUP
#
# The message's sent by setsockopt actually, such as,
# for IPv4
# setsockopt(s, IPPROTO_IP, MCAST_JOIN_GROUP, &command, sizeof(command));
# for IPv6
# setsockopt(s, IPPROTO_IPV6, MCAST_JOIN_GROUP, &command, sizeof(command));
# Methods defined in class MulticastReport encapsulate calling for setsockopt.
#
################################################################################

import ctypes
import socket
import struct
import sys
from ctypes.util import find_library

class MulticastReport():
    ''' Class to provide attributes and method for multicast report message '''

    def __init__(self, family):
        ''' Constructor to create MulticastReport object

        @param family:  family of ip address (socket.AF_INET/socket.AF_INET6)
        '''

        self.family = family
        if self.family == socket.AF_INET:
            self.level = socket.IPPROTO_IP
        else:
            self.level = socket.IPPROTO_IPV6
        self.socktype = socket.SOCK_DGRAM
        self.proto = socket.IPPROTO_UDP
        self.socket = socket.socket(self.family, self.socktype, self.proto)
        self.generate_methods()

    def set_multicast_params(self, multicast_dict):
        self.group_address = multicast_dict['group_address']
        self.grp_sockaddr_storage = \
            self.construct_sockaddr_storage(self.group_address)
        self.interface = multicast_dict['interface']
        # To construct network interface local index
        # The if_nametoindex function converts the ANSI interface name
        # for a network interface to the local index for the interface.
        self.interface_index = struct.pack('I', self.if_nametoindex())
        if multicast_dict.has_key('source_addr_array'):
            self.source_addr_array = multicast_dict['source_addr_array']

    def get_multicast_params(self):
        mcast_param_dict = {}
        if self.group_address is not None:
            mcast_param_dict['group_address'] = self.group_address
        if self.interface is not None:
            mcast_param_dict['interface'] = self.interface
        if self.source_addr_array is not None:
            mcast_param_dict['source_addr_array'] = self.source_addr_array
        return mcast_param_dict

    def if_nametoindex(self):
        ''' libc definition of if_nametoindex, returns the index of the
        network interface corresponding to the interface name, e.g., eth0
        '''
        try:
            c_library = find_library('c')
            _libc = ctypes.cdll.LoadLibrary(c_library)
            return _libc.if_nametoindex(self.interface)
        except:
            print 'ERROR: calling libc.if_nametoindex\n'
            sys.exit(1)

    def construct_sockaddr_storage(self, address):
        ''' To construct 'struct __kernel_sockaddr_storage' defined
        in linux/socket.h and use struct sockaddr_in or sockaddr_in6 to
        fill __data

        @param address: ipv4 or ipv6 address, e.g. 192.168.1.1, 2002::1:1
        '''

        sockaddr_storage = None
        if self.family == socket.AF_INET:
            ''' sockaddr_storage for ipv4'''
            sockaddr_storage = struct.pack('H', self.family) + \
                            struct.pack('H', 0) + \
                            socket.inet_pton(self.family, address) + \
                            struct.pack('120x')
        else:
            ''' sockaddr_storage for ipv6'''
            sockaddr_storage = struct.pack('H', self.family) + \
                            struct.pack('H', 0) + \
                            struct.pack('I', 0) + \
                            socket.inet_pton(self.family, address) + \
                            struct.pack('I', 0) + \
                            struct.pack('100x')

        return sockaddr_storage

    def construct_group_req(self):
        ''' To construct 'struct group_req' in linux/in.h
        '''

        group_req = self.interface_index + self.grp_sockaddr_storage
        return group_req

    def construct_group_source_req(self, source_addr):
        ''' To construct 'struct group_source_req' linux/in.h

        @param source_addr: ipv4 or ipv6 address
        '''

        group_source_req = self.interface_index + self.grp_sockaddr_storage + \
                self.construct_sockaddr_storage(source_addr)
        return group_source_req

    def generate_methods(self):
        ''' To generate methods in this class, which may be used
        to send multicast report message for IGMP or MLD protocols.
        Methods' name are key of mcast_option dict below, may be
        MCAST_JOIN_GROUP, MCAST_BLOCK_SOURCE, etc.
        The generated methods look like,
            def MCAST_JOIN_GROUP(self)
            def MCAST_BLOCK_SOURCE(self)
            def MCAST_UNBLOCK_SOURCE(self)
            def MCAST_LEAVE_GROUP(self)
            def MCAST_JOIN_SOURCE_GROUP(self)
            def MCAST_LEAVE_SOURCE_GROUP(self)
        To generate them dynamically in order to reduce duplicated codes.
        42, 43, 44, 45, 46 and 47 are values of socket options defined in
        /usr/include/bits/in.h
        /* group_req: join any-source group */
        #define MCAST_JOIN_GROUP 42
        /* group_source_req: block from given group */
        #define MCAST_BLOCK_SOURCE 43
        /* group_source_req: unblock from given group*/
        #define MCAST_UNBLOCK_SOURCE 44
        /* group_req: leave any-source group */
        #define MCAST_LEAVE_GROUP 45
        /* group_source_req: join source-spec gr */
        #define MCAST_JOIN_SOURCE_GROUP 46
        /* group_source_req: leave source-spec gr*/
        #define MCAST_LEAVE_SOURCE_GROUP 47
        '''

        mcast_options = {
            'MCAST_JOIN_GROUP'         : 42,
            'MCAST_BLOCK_SOURCE'       : 43,
            'MCAST_UNBLOCK_SOURCE'     : 44,
            'MCAST_LEAVE_GROUP'        : 45,
            'MCAST_JOIN_SOURCE_GROUP'  : 46,
            'MCAST_LEAVE_SOURCE_GROUP' : 47,
        }

        for mcast_opt, opt_val in mcast_options.items():
            if not hasattr(socket, mcast_opt):
                setattr(socket, mcast_opt, opt_val)
            self.add_method(mcast_opt)

    def add_method(self, mcast_opt):
        def dummy(source_array=None):
            return self.command(mcast_opt, source_array)
        setattr(self, mcast_opt, dummy)
        setattr(dummy, '__name__', mcast_opt)

    def command(self, mcast_opt, source_array=None):
        if ('SOURCE' not in mcast_opt):
            ''' multicast reports without source address '''
            self.socket.setsockopt(self.level,
                getattr(socket, mcast_opt), self.construct_group_req())
        else:
            ''' multicast reports with source addresses involved '''
            if source_array is None:
                source_array = self.source_addr_array

            for source_addr in source_array:
                self.socket.setsockopt(self.level,
                    getattr(socket, mcast_opt),
                    self.construct_group_source_req(source_addr))

if __name__ == '__main__':
    ''' unit test and samples to demo class MulticastReport
    '''

    mcast_obj = MulticastReport(socket.AF_INET)
    multicast_dict = {}
    multicast_dict['interface'] = 'eth0'
    multicast_dict['group_address'] = '239.1.1.1'
    multicast_dict['source_addr_array'] = ['192.168.1.1', '192.168.1.2']
    mcast_obj.set_multicast_params(multicast_dict)
    mcast_obj.MCAST_JOIN_GROUP()
    mcast_obj.MCAST_BLOCK_SOURCE()
    print 'IGMPv3 exclude mode, block source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_UNBLOCK_SOURCE(['192.168.1.1'])
    print 'IGMPv3 exclude mode, unblock source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_BLOCK_SOURCE(['192.168.1.3'])
    print 'IGMPv3 exclude mode, block source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_LEAVE_GROUP()
    print 'IGMPv3 leave group message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)

    mcast_obj = MulticastReport(socket.AF_INET6)
    multicast_dict = {}
    multicast_dict['interface'] = 'eth0'
    multicast_dict['group_address'] = 'ff39::1:1'
    multicast_dict['source_addr_array'] = ['2002::1:1', '2002::1:2']
    mcast_obj.set_multicast_params(multicast_dict)
    mcast_obj.MCAST_JOIN_GROUP()
    mcast_obj.MCAST_BLOCK_SOURCE()
    print 'MLDv2 exclude mode, block source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_UNBLOCK_SOURCE(['2002::1:1'])
    print 'MLDv2 exclude mode, unblock source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_BLOCK_SOURCE(['2002::1:3'])
    print 'MLDv2 exclude mode, block source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_LEAVE_GROUP()
    print 'MLDv2 leave group was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)

    mcast_obj = MulticastReport(socket.AF_INET)
    multicast_dict = {}
    multicast_dict['interface'] = 'eth0'
    multicast_dict['group_address'] = '239.1.1.1'
    multicast_dict['source_addr_array'] = ['192.168.1.1', '192.168.1.2']
    mcast_obj.set_multicast_params(multicast_dict)
    mcast_obj.MCAST_JOIN_SOURCE_GROUP()
    print 'IGMPv3 include mode, join source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_LEAVE_SOURCE_GROUP(['192.168.1.1'])
    print 'IGMPv3 include mode, leave source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_JOIN_SOURCE_GROUP(['192.168.1.3'])
    print 'IGMPv3 include mode, join source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_LEAVE_SOURCE_GROUP(['192.168.1.2', '192.168.1.3'])
    print 'IGMPv3 include mode, leave source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)

    mcast_obj = MulticastReport(socket.AF_INET6)
    multicast_dict = {}
    multicast_dict['interface'] = 'eth0'
    multicast_dict['group_address'] = 'ff39::1:1'
    multicast_dict['source_addr_array'] = ['2002::1:1', '2002::1:2']
    mcast_obj.set_multicast_params(multicast_dict)
    mcast_obj.MCAST_JOIN_SOURCE_GROUP()
    print 'MLDv2 include mode, join source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_LEAVE_SOURCE_GROUP(['2002::1:1'])
    print 'MLDv2 include mode, leave source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_JOIN_SOURCE_GROUP(['2002::1:3'])
    print 'MLDv2 include mode, join source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
    mcast_obj.MCAST_LEAVE_SOURCE_GROUP(['2002::1:2', '2002::1:3'])
    print 'MLDv2 include mode, leave source message was sent'
    print 'The packet may be captured by tcpdump, press Enter to continue...'
    sys.stdin.read(1)
