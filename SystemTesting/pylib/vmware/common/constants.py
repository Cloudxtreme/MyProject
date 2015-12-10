# Copyright (C) 2014 VMware, Inc. All rights reserved.
#
# Constants used by library.
#

import httplib


class Constant(object):
    """Base class for constants.

    Object instantiation is blocked. Force consumers to reference the class.
    values.
    """
    def __init__(self, *args, **kwargs):
        raise AssertionError("Constant object can not be instantiated: %s" %
                             type(self))


class ConnectionType(Constant):
    """Connection Types"""
    SOAP = "SOAP"
    SSH = "SSH"
    EXPECT = "EXPECT"


class ExecutionType(Constant):
    """Execution Types"""
    API = "api"
    CMD = "cmd"
    CLI = "cli"
    UI = "ui"


class Network(Constant):
    """Networking"""
    class Port(Constant):
        """Network Ports"""
        VIM_SOAP = httplib.HTTPS_PORT


class PathType(Constant):
    """Path Types"""
    ATTRIBUTE = "attribute"
    ENTITY = "entity"


class VimTaskState(Constant):
    """Vim Task States"""
    RUNNING = "running"


class Service(Constant):
    """
    Service Related constants
    """
    SERVICE_CMD = '/etc/init.d/%s %s'
    START = 'start'
    RESTART = 'restart'
    KILL = 'kill'
    STOP = 'stop'
    STATUS = 'status'
    STATUS_RUNNING = 'is running'
    STATUS_NOT_RUNNING = 'is not running'
    UNKNOWN = 'unknown'
    STARTED = 'started'
    STOPPED = 'stopped'
    ALREADY_RUNNING = 'already running'


class HostAction(Constant):
    """Host Actions"""
    REBOOT = "reboot"
    POWEROFF = "poweroff"
    SHUTDOWN = "shutdown"


class VimApiQuery(Constant):
    """Vim-Api Queries"""
    VM = 'vm'


class Result(Constant):
    """Defines Success and Failure."""
    SUCCESS = "Success"
    FAILURE = "Failure"
    TRUE = 1
    FALSE = 0


# TODO(James, Giri): Handle timeouts in a trackable manner, probably by
# avoiding time.sleep(). Constants here are a placeholder to collect values.
class Timeout(Constant):
    """Timeout Values"""
    SSH_CONNECT = 10
    VIMTASK_COMPLETION = 60
    ESX_ENTER_MAINT_MODE = 60
    HOST_REBOOT_MAX = 300
    POST_REBOOT_SLEEP = 60
    FORM_CCP_CLUSTER = 100
    DEFAULT_EXPECT_REQUEST_TIMEOUT = 300


class TCPConnectionState(Constant):
    """Connection states"""
    ESTABLISHED = "ESTABLISHED"
    SYN_SENT = "SYN_SENT"
    SYN_RECV = "SYN_RECV"
    FIN_WAIT1 = "FIN_WAIT1"
    FIN_WAIT2 = "FIN_WAIT2"
    TIMEWAIT = "TIMEWAIT"
    CLOSED = "CLOSED"
    CLOSE_WAIT = "CLOSE_WAIT"
    LAST_ACK = "LAST_ACK"
    LISTEN = "LISTEN"
    CLOSING = "CLOSING"
    UNKNOWN = "UNKNOWN"
    STATES = (ESTABLISHED, SYN_SENT, SYN_RECV, FIN_WAIT1, FIN_WAIT2, TIMEWAIT,
              CLOSED, CLOSE_WAIT, LAST_ACK, LISTEN, CLOSING, UNKNOWN)


class Regex(Constant):
    ALPHA_NUMBERIC = '[a-zA-Z0-9]+'


class ManagerCredential(Constant):
    """Manager Credentials"""
    USERNAME = "admin"
    PASSWORD = "default"


class VSMCredential(Constant):
    """Manager Credentials"""
    USERNAME = "admin"
    PASSWORD = "default"


class EdgeCredential(Constant):
    """Manager Credentials"""
    USERNAME = "admin"
    PASSWORD = "default"


class HTTPVerb(Constant):
    POST = "POST"
    PUT = "PUT"
    GET = "GET"
    DELETE = "DELETE"


class ControllerCredential(Constant):
    """Controller Credentials"""
    USERNAME = "admin"
    PASSWORD = "default"
    SHELL_PASSWORD = "vmware"


class VSMterms(Constant):
    PASSWORD = "C@shc0w12345"


class NSXPackages(Constant):
    """Package names"""
    NSXA = "nsxa"
    NSX_AGENT = "nsx-agent"
    NSX_MPA = "nsx-mpa"
    RPM_KMOD_OPENVSWITCH = "kmod-openvswitch"
    OVS_L3D = "ovs-l3d"
    NSX_COMPONENTS = (OVS_L3D, NSXA, NSX_MPA, NSX_AGENT)


class ManagerScriptPath(Constant):
    """script paths in Manager"""
    NSXNODECLEANUPSCRIPTPATH = "/opt/vmware/bin/nsx_proton_cleanup"
