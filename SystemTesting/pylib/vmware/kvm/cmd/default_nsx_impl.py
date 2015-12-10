import os

import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.interfaces.nsx_interface as nsx_interface
import vmware.linux.cmd.linux_fileops_impl as linux_fileops_impl
import vmware.kvm.cmd.default_service_impl as default_service_impl
import vmware.linux.linux_helper as linux_helper

Linux = linux_helper.Linux
DefaultServiceImpl = default_service_impl.DefaultServiceImpl
DefaultFileOpsImpl = linux_fileops_impl.LinuxFileOpsImpl


class DefaultNSXImpl(nsx_interface.NSXInterface):
    NSXA = constants.NSXPackages.NSXA
    NSX_MPA = constants.NSXPackages.NSX_MPA
    NSX_AGENT = constants.NSXPackages.NSX_AGENT
    OVS_L3D = constants.NSXPackages.OVS_L3D
    NSXAGENT_PATH = "/opt/vmware/nsx-agent/bin/nsx-agent.sh"
    RSYSLOG_PATH = "/etc/rsyslog.conf"
    RSYSLOG = "rsyslog"
    ALLOWED_LOG_LEVELS = ("debug")
    NSX_COMPONENTS = constants.NSXPackages.NSX_COMPONENTS

    @classmethod
    def set_log_level(cls, client_object, component=None, log_level=None):
        """
        Sets the log level of components.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type log_level: str
        @param log_level: Specifies whether the log level is being increased or
            decreased. Only supports increasing the log level now.
        """
        if component not in cls.NSX_COMPONENTS:
            response = ("Only %r components are allowed, got: %r" %
                        (cls.NSX_COMPONENTS, component))
            raise errors.CLIError(
                status_code=common.status_codes.INVALID_PARAM, reason=response)
        if not log_level.lower() in cls.ALLOWED_LOG_LEVELS:
            response = ("Only %r log levels are allowed, got: %r" %
                        (cls.ALLOWED_LOG_LEVELS, log_level))
            raise errors.CLIError(
                status_code=common.status_codes.INVALID_PARAM, reason=response)
        component_map = {
            constants.NSXPackages.OVS_L3D: cls._set_l3d_log_level,
            constants.NSXPackages.NSXA: cls._set_nsxa_log_level,
            constants.NSXPackages.NSX_MPA: cls._set_nsxmpa_log_level,
            constants.NSXPackages.NSX_AGENT: cls._set_nsxagent_log_level
        }
        component_map[component](client_object, log_level=log_level)

    @classmethod
    def _set_l3d_log_level(cls, client_object, log_level=None):
        """
        Sets the log level of ovs-l3d.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type log_level: str
        @param log_level: Specifies whether the log level is being increased or
            decreased.
        """
        ovsl3d_debug = "ovs-appctl -t ovs-l3d vlog/set dbg"
        client_object.connection.request(command=ovsl3d_debug)

    @classmethod
    def _set_nsxagent_log_level(cls, client_object, log_level=None):
        """
        Sets the log level of nsx-agent.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type log_level: str
        @param log_level: Specifies whether the log level is being increased or
            decreased.
        """
        regex = r'^export GLOG_v=\$VERBOSE_LEVEL$'
        substitution = 'export GLOG_v=3'
        Linux.replace_in_file(
            client_object=client_object, path=cls.NSXAGENT_PATH, regex=regex,
            substitution=substitution)
        DefaultServiceImpl.restart_service(
            client_object, service_name=cls.NSX_AGENT)

    @classmethod
    def _set_nsxmpa_log_level(cls, client_object, log_level=None):
        """
        Sets the log level of nsx-mpa.

        Method would look for this pattern:
            $ModLoad imuxsock
        and would add following lines after it:
            $SystemLogRateLimitInterval 0
            $SystemLogRateLimitBurst 0

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type log_level: str
        @param log_level: Specifies whether the log level is being increased or
            decreased.
        """
        restart_service = False
        rate_interval_exists = DefaultFileOpsImpl.file_find_context(
            client_object, file_name=cls.RSYSLOG_PATH,
            start_str="\$ModLoad imuxsock",
            end_str="\$SystemLogRateLimitInterval 0")
        if common.status_codes.FAILURE == rate_interval_exists:
            regex = r'^\$ModLoad imuxsock.*'
            substitution = (r"$ModLoad imuxsock\%s"
                            "$SystemLogRateLimitInterval 0" % os.linesep)
            Linux.replace_in_file(
                client_object=client_object, path=cls.RSYSLOG_PATH,
                regex=regex, substitution=substitution)
            restart_service = True
        rate_burst_exists = DefaultFileOpsImpl.file_find_context(
            client_object, file_name=cls.RSYSLOG_PATH,
            start_str="\$SystemLogRateLimitInterval 0",
            end_str="\$SystemLogRateLimitBurst 0")
        if common.status_codes.FAILURE == rate_burst_exists:
            regex = r"^\$SystemLogRateLimitInterval 0$"
            substitution = (r"$SystemLogRateLimitInterval 0\%s"
                            "$SystemLogRateLimitBurst 0" % os.linesep)
            Linux.replace_in_file(
                client_object=client_object, path=cls.RSYSLOG_PATH,
                regex=regex, substitution=substitution)
            restart_service = True
        if restart_service:
            DefaultServiceImpl.restart_service(
                client_object, service_name=cls.RSYSLOG)
            DefaultServiceImpl.restart_service(
                client_object, service_name=cls.NSX_MPA)

    @classmethod
    def _set_nsxa_log_level(cls, client_object, log_level=None):
        """
        Sets the log level of nsxa log.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type log_level: str
        @param log_level: Specifies whether the log level is being increased or
            decreased.
        """
        regex = (r'\*\.info;mail\.none;authpriv\.none;cron\.none')
        substitution = ("*.info;*.debug;mail.none;authpriv.none;"
                        "cron.none")
        Linux.replace_in_file(
            client_object=client_object, path=cls.RSYSLOG_PATH, regex=regex,
            substitution=substitution)
        DefaultServiceImpl.restart_service(
            client_object, service_name=cls.RSYSLOG)
        DefaultServiceImpl.restart_service(
            client_object, service_name=cls.NSXA)
