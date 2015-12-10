import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class NSX(base.Base):

    def __init__(self, ip=None, username=None, password=None,
                 root_password=None, cert_thumbprint=None, build=None):
        super(NSX, self).__init__()
        self.ip = ip
        self.username = username
        self.password = password
        self.root_password = root_password
        self.cert_thumbprint = cert_thumbprint
        self.build = build

    @auto_resolve(labels.POWER)
    def configure_power_state(self, execution_type=None, **kwargs):
        """
        Shutdown/restart the NSX Manager appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def reboot(self, execution_type=None, **kwargs):
        """
        Restart the NSX Manager appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.SERVICE)
    def configure_service_state(self, execution_type=None,
                                service_name=None, state=None, **kwargs):
        """
        Stop/Start/Restart services of NSX Manager appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def node_network_partitioning(self, manager_ip=None, operation=None,
                                  **kwargs):
        """
        Isolate node from cluster by configuring iptable rules
        @param manager_ip: IP address of manager with which connection will be
        broken
        @type manager_ip: str
        @param operation: Whether to set or rest the rule
        @type operation: str
        """
        pass

    @auto_resolve(labels.CRUD)
    def get_status(self, execution_type=None, **kwargs):
        """
        Get Status of NSX Manager appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_version(self, execution_type=None, **kwargs):
        """
        Verify the version of NSX Manager using show version command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_application_version(self, execution_type=None,
                                   application_name=None, **kwargs):
        """
        Verify the version of Python component on NSXManager
        """
        pass

    @auto_resolve(labels.CRUD, execution_type=constants.ExecutionType.CLI)
    def get_manager_thumbprint(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD, execution_type=constants.ExecutionType.CLI)
    def get_manager_messaging_thumbprint(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_application_processes(self, execution_type=None,
                                     application_name=None, **kwargs):
        """
        Verify the version of application processes on NSXManager
        """
        pass

    @auto_resolve(labels.CRUD)
    def get_node_id(self, execution_type=None, **kwargs):
        """
        Gets the node id of nsx manager by querying the cluster
        node
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_show_interface(self, execution_type=None,
                              vnic_name=None, **kwargs):
        """
        Verify interfaces using show interface command.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def show_interfaces(self, execution_type=None,
                        **kwargs):
        """
        Get interfaces using show interfaces command.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def read_clock_output(self, execution_type=None, **kwargs):
        """
        Run show clock CLI on NSXManager
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_show_certificate(self, execution_type=None,
                                thumbprint=None, **kwargs):
        """
        Verify certificate & thumbprint using show api certificate command.

        """

    @auto_resolve(labels.APPLIANCE)
    def set_clock_nsxmgr(self, execution_type=None, **kwargs):
        """
        Run and verify clock set NSXManager CLI
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_system_config(self, execution_type=None,
                          system_parameter=None, **kwargs):
        """
        Get the system memory of the NSX Manager using show
        system memory command
        Get the total cpus on the NSX Manager using
        show system cpu command
        Get the storage size on the NSX Manager using
        show system storage command
        Get the tx and rx packets on the NSX Manager using
        show system network-stats command
        The up-time of the system is valid, that is at-least one amongst the
        days, minutes or seconds, is greater than 0'
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_clock_set(self, execution_type=None, **kwargs):
        """
        Verify clock set CLI on NSXManager
        """
        pass

    @auto_resolve(labels.CRUD)
    def get_base_url(self, execution_type=None, **kwargs):
        """
        Gets the automation url of nsx manager
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def list_commands(self, execution_type=None,
                      terminal=None, **kwargs):
        """
        Get list of commands.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_content(self, execution_type=None, content_type=None, **kwargs):
        """
        Run command on NSXManager and return output
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def list_log_files(self, execution_type=None, **kwargs):
        """ Get list of log files. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def trace_route(self, execution_type=None, hostname=None, **kwargs):
        """ Trace route of host. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def set_hostname(self, execution_type=None, **kwargs):
        """
        Run hostname HOSTNAME command on NSXManager.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def read_hostname(self, execution_type=None, **kwargs):
        """
        Run hostname HOSTNAME command on NSXManager.
        """
    @auto_resolve(labels.APPLIANCE)
    def run_command(self, execution_type=None, **kwargs):
        """ Run short version of CLI. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def exit_from_terminal(self, execution_type=None, **kwargs):
        """ Run cli to exit current mode. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_server_auth(self, execution_type=None, **kwargs):
        """
        Get the Tacacs Server Authentication using show
        tacacs-server-authentication command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_ip_route(self, execution_type=None, **kwargs):
        """
        Get the ip routing of the NSX Manager using
        show ip route command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def set_user_password(self, execution_type=None, **kwargs):
        """ Run cli to change NSXManager password. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def show_arp(self, execution_type=None, **kwargs):
        """ Run cli to show arp. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def show_ip_sockets(self, execution_type=None, **kwargs):
        """ Run cli to show ip sockets. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def search_log(self, execution_type=None, **kwargs):
        """
        Run command on NSXManager, return output and check the
        desired string in the output
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_cluster_details(self, execution_type=None, **kwargs):
        """
        Get the ip of the node and the number of nodes in the management
        cluster using the show management-cluster status command.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_file_systems(self, execution_type=None, **kwargs):
        """
        Get the file systems size on the NSX Manager using
        show file systems CLI command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_file_present(self, execution_type=None, **kwargs):
        """
        Verify the desired file is present on the NSX Manager using
        linux command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_password_encrypted(self, execution_type=None, **kwargs):
        """
        Verify if all the users have encrypted passwords
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_global_config(self, execution_type=None, **kwargs):
        """
        Get the nsx manager global configuration using 'show configuration
        global' command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def create_tech_support_tar(self, execution_type=None, **kwargs):
        """
        Create tech-support tar file
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_dir_list(self, execution_type=None, **kwargs):
        """
        Get the list of file present in nsxcli filestore
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_ping_output(self, execution_type=None, **kwargs):
        """
        Get the ping IP/Hostname status
        """
    @auto_resolve(labels.APPLIANCE)
    def delete_file(self, execution_type=None, **kwargs):
        """
        Remove file using delete FILENAME CLI
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def debug_packet_capture(self, execution_type=None, **kwargs):
        """
        Run debug packet capture interface CLI
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def set_banner_motd(self, execution_type=None, **kwargs):
        """
        Set banner using banner motd CLI
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_motd(self, execution_type=None, **kwargs):
        """
        Get content of /etc/motd.tail file
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_process_monitor(self, execution_type=None, **kwargs):
        """
        Get output of show process monitor
        """

    @auto_resolve(labels.APPLIANCE)
    def set_ntp_server(self, execution_type=None, **kwargs):
        """
        Set NTP server using 'ntp server HOSTNAME' CLI
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def read_system_memory(self, execution_type=None, **kwargs):
        """
        Read /proc/meminfo file to return system memory details
        """

    @auto_resolve(labels.APPLIANCE)
    def get_ntp_associations(self, execution_type=None, **kwargs):
        """
        Get table having 'show ntp associations' CLI output
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def configure_ip_route(self, execution_type=None, **kwargs):
        """
        Set, reset ip route using 'ip route CIDR GATEWAY' and
        'no ip route CIDR GATEWAY' CLI
        """

    @auto_resolve(labels.APPLIANCE)
    def show_ip_route(self, execution_type=None, **kwargs):
        """
        Get table having cidr and gateway for each ip route using
        'show ip route' CLI
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def configure_tacacs_server(self, execution_type=None, **kwargs):
        """
        configure new TACACS+ server
        """

    @auto_resolve(labels.APPLIANCE)
    def configure_auth_type(self, execution_type=None, **kwargs):
        """
        configure TACACS+ authentication
        """
    @auto_resolve(labels.APPLIANCE)
    def copy_file(self, execution_type=None, **kwargs):
        """
        Copy a given file to and from given URL
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def move_file(self, execution_type=None, **kwargs):
        """
        Move a file from one folder to other on NSXManager
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def delete_backend_file(self, execution_type=None, **kwargs):
        """
        Delete a file from backend on NSXManager
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def check_cluster_backup_file(self, execution_type=None, **kwargs):
        """
        check only one cluster backup file exists
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def check_node_backup_file(self, execution_type=None, **kwargs):
        """
        check separate node backup file exists
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def file_append(self, execution_type=None, file_name=None,
                    append_string=None, size=None):
        """
        Append text to file
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def file_find_context(self, execution_type=None, file_name=None,
                          start_str=None, end_str=None, **kwargs):
        """Find a string in a file"""
        pass

    @auto_resolve(labels.FILEOPS)
    def query_file(self, execution_type=None, file_name=None,
                   grep_after=None, grep_string=None, max_wait=None,
                   pattern=None, count=None, **kwargs):
        """Wait for the desired string to appear in a file"""
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_aggregation_transportnode_status(self, execution_type=None,
                                             **kwargs):
        """Get status summary of all transport nodes under MP"""
        pass

    @auto_resolve(labels.FILEOPS)
    def find_pattern_count(cls, client_object, file_name=None,
                           grep_string=None, grep_after=None,
                           pattern=None, **kwargs):
        """Count number of patterns in file """
        pass

    @auto_resolve(labels.APPLIANCE)
    def node_cleanup(self, execution_type=None, **kwargs):
        """
        Run a cleanup script from backend on NSXManager
        """
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_node_status(self, execution_type=None, **kwargs):
        """
        Get the status for a cluster node as reported by aggregation service.
        """
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_node_interfaces(self, execution_type=None, **kwargs):
        """
        Get the information of cluster node interfaces as reported by
        aggregation service.
        """
        pass
