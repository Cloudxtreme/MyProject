class ApplianceInterface(object):
    """Interface class to implement appliance related operations."""

    @classmethod
    def get_management_mac(cls, client_object, **kwargs):
        """ Method to get_management_mac of this vm. """
        raise NotImplementedError

    @classmethod
    def node_network_partitioning(cls, client_object, **kwargs):
        """ Method to isolate node from cluster """
        raise NotImplementedError

    @classmethod
    def get_management_ip(cls, client_object, **kwargs):
        """ Method to get_management_ip of this vm. """
        raise NotImplementedError

    @classmethod
    def get_management_ipv6(cls, client_object, **kwargs):
        """ Method to get IPv6 address of management interface of this vm. """
        raise NotImplementedError

    @classmethod
    def verify_version(cls, client_obj, **kwargs):
        """ Method to execute command "show version" on NSX Manager &
         NSX Controller"""
        raise NotImplementedError

    @classmethod
    def verify_application_version(cls, client_obj, application_name,
                                   **kwargs):
        """ Method to get Application version from NSX Manager """
        raise NotImplementedError

    @classmethod
    def get_interface_statistics(cls, client_object, **kwargs):
        """ Method to get_interface_statistics of NSXManager. """
        raise NotImplementedError

    @classmethod
    def verify_application_processes(cls, client_obj, application_name,
                                     **kwargs):
        """ Method to get Application processes from NSX Manager """
        raise NotImplementedError

    @classmethod
    def verify_show_interface(cls, client_obj, vnic_name, **kwargs):
        """ Method to verify show interface command. """
        raise NotImplementedError

    @classmethod
    def read_clock_output(cls, client_obj, **kwargs):
        """ Method to run show clock CLI on NSX Manager """
        raise NotImplementedError

    @classmethod
    def verify_show_certificate(cls, client_obj, thumbprint, **kwargs):
        """ Method to verify show certificate command. """
        raise NotImplementedError

    @classmethod
    def get_system_config(cls, client_obj, system_parameter, **kwargs):
        """ Method to execute command "show system memory" on NSX Manager
        and Controller
        Method to execute command "show system cpu" on NSX Manager
        and Controller
        Method to execute command "show system storage" on NSX Manager
        and Controller
        Method to execute command "show system network-stats" NSX Manager
        and Controller
        Method to execute command "show system uptime" on  NSX Manager
        and Controller
        """
        raise NotImplementedError

    @classmethod
    def set_clock_nsxmgr(cls, client_obj, **kwargs):
        """ Method to run clock set CLI on NSX Manager """
        raise NotImplementedError

    @classmethod
    def verify_clock_set(cls, client_obj, **kwargs):
        """ Method to verify clock set CLI on NSX Manager """
        raise NotImplementedError

    @classmethod
    def list_commands(cls, client_obj, terminal, **kwargs):
        """ Method to list commands. """
        raise NotImplementedError

    @classmethod
    def get_content(cls, client_obj, content_type, **kwargs):
        """ Method to execute command on NSX Manager
        and return output """
        raise NotImplementedError

    @classmethod
    def list_log_files(cls, client_obj, **kwargs):
        """ Method to list log files. """
        raise NotImplementedError

    @classmethod
    def trace_route(cls, client_obj, hostname, **kwargs):
        """ Trace route of hostname. """
        raise NotImplementedError

    @classmethod
    def set_hostname(cls, client_obj, **kwargs):
        """ Method to execute hostname HOSTNAME command"""
        raise NotImplementedError

    @classmethod
    def read_hostname(cls, client_obj, **kwargs):
        """ Method to execute hostname HOSTNAME command"""
        raise NotImplementedError

    @classmethod
    def run_command(cls, client_obj, **kwargs):
        """ Method to run short version of CLI. """
        raise NotImplementedError

    @classmethod
    def exit_from_terminal(cls, client_obj, **kwargs):
        """ Method to exit from current CLI mode. """
        raise NotImplementedError

    @classmethod
    def get_server_auth(cls, client_obj, **kwargs):
        """
        Method to execute command "show tacacs-server-authentication"
        on NSX manager
        """
        raise NotImplementedError

    @classmethod
    def get_ip_route(cls, client_obj, **kwargs):
        """ Method to execute command "show ip route" command on NSX Manager
        """
        raise NotImplementedError

    @classmethod
    def search_log(cls, client_obj, **kwargs):
        """ Method to execute command on NSX Manager,
        get the output and search for the desired string in the output"""
        raise NotImplementedError

    @classmethod
    def get_cluster_details(cls, client_obj, **kwargs):
        """ Method to execute command "show management-cluster status" command
        on NSX Manager
        """
        raise NotImplementedError

    @classmethod
    def set_user_password(cls, client_obj, **kwargs):
        """ Method to change NSXManager password. """
        raise NotImplementedError

    @classmethod
    def show_arp(cls, client_obj, **kwargs):
        """ Method to run show arp. """
        raise NotImplementedError

    @classmethod
    def show_ip_sockets(cls, client_obj, **kwargs):
        """ Method to run show ip sockets. """
        raise NotImplementedError

    @classmethod
    def get_file_systems(cls, client_obj, **kwargs):
        """ Method to execute command "show file systems" command
        on NSX Manager
        """
        raise NotImplementedError

    @classmethod
    def verify_file_present(cls, client_obj, **kwargs):
        """ Method to verify if the desired file is present
        on NSX Manager
        """
        raise NotImplementedError

    @classmethod
    def verify_encrypted_password(cls, client_obj, **kwargs):
        """ Method to verify if all the users have encrypted passwords
        on NSX Manager
        """
        raise NotImplementedError

    @classmethod
    def get_global_config(cls, client_obj, **kwargs):
        """
        Method to execute command "show configuration global" on NSX Manager
        """
        raise NotImplementedError

    @classmethod
    def create_tech_support_tar(cls, client_obj, **kwargs):
        """ Method run show tech-support CLI
        """
        raise NotImplementedError

    @classmethod
    def get_dir_list(cls, client_obj, **kwargs):
        """ Method to get list of file present in nsxcli filestore
        """
        raise NotImplementedError

    @classmethod
    def get_ping_output(cls, client_obj, **kwargs):
        """ Method to get ping IP/Hostname status
        """
        raise NotImplementedError

    @classmethod
    def delete_file(cls, client_obj, **kwargs):
        """ Method to remove file using delete FILENAME CLI
        """
        raise NotImplementedError

    @classmethod
    def debug_packet_capture(cls, client_obj, **kwargs):
        """ Method to run debug packet capture interface CLI
        """
        raise NotImplementedError

    @classmethod
    def set_banner_motd(cls, client_obj, **kwargs):
        """ Method to banner using banner motd CLI
        """
        raise NotImplementedError

    @classmethod
    def get_motd(cls, client_obj, **kwargs):
        """ Method to get content of /etc/motd.tail file
        """
        raise NotImplementedError

    @classmethod
    def get_process_monitor(cls, client_obj, **kwargs):
        """ Method to get output of show process monitor CLI
        """
        raise NotImplementedError

    @classmethod
    def set_ntp_server(cls, client_obj, **kwargs):
        """ Method to set NTP server
        """
        raise NotImplementedError

    @classmethod
    def read_system_memory(cls, client_obj, **kwargs):
        """ Method to read /proc/meminfo file to get the system memory details
        """
        raise NotImplementedError

    @classmethod
    def get_ntp_associations(cls, client_obj, **kwargs):
        """ Method to get ntp server association list
        """
        raise NotImplementedError

    @classmethod
    def configure_ip_route(cls, client_obj, **kwargs):
        """ Method to set and reset ip route
        """
        raise NotImplementedError

    @classmethod
    def show_ip_route(cls, client_obj, **kwargs):
        """ Method to get cidr and gateway for each ip route using show ip
        route CLI
        """
        raise NotImplementedError

    @classmethod
    def configure_tacacs_server(cls, client_obj, **kwargs):
        """ Method to set new TACACS+ server
        """
        raise NotImplementedError

    @classmethod
    def configure_auth_type(cls, client_obj, **kwargs):
        """ Method to set authentication type
        """
        raise NotImplementedError

    @classmethod
    def get_configuration(cls, client_obj, **kwargs):
        """ Method to verify NSX Controller's Configurations
        """
        raise NotImplementedError

    @classmethod
    def show_interfaces(cls, client_obj, **kwargs):
        """ Method to verify show interfaces command on NSX Controller
        """
        raise NotImplementedError

    @classmethod
    def regenerate_certificate(cls, client_obj, **kwargs):
        """ Method to regenerate certificate on an appliance
        """
        raise NotImplementedError

    @classmethod
    def node_cleanup(cls, client_obj, **kwargs):
        raise NotImplementedError
