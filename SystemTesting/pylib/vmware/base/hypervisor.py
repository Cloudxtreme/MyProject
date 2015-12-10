import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class Hypervisor(base.Base):

    def __init__(self, ip=None, username=None, password=None, parent=None,
                 version=None):
        super(Hypervisor, self).__init__(version=version)
        self.ip = ip
        self.username = username
        self.password = password
        self.parent = parent

    @auto_resolve(labels.POWER)
    def on(self, execution_type=None, **kwargs):
        """
        Powers on a hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def off(self, execution_type=None, **kwargs):
        """
        Powers off the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def enter_maintenance_mode(self, execution_type=None, **kwargs):
        """
        Forces the hypervisor to enter maintenance mode.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def exit_maintenance_mode(self, execution_type=None, **kwargs):
        """
        Forces the hypervisor to exit maintenance mode.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def wait_for_reboot(self, execution_type=None, timeout=None, **kwargs):
        """
        Waits for reboot on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type timeout: int
        @param timeout: Value in seconds after the wait for reboot times out.
        """
        pass

    @auto_resolve(labels.POWER)
    def reset(self, execution_type=None, **kwargs):
        """
        Resets the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def shutdown(self, execution_type=None, **kwargs):
        """
        Shuts down the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.POWER)
    def reboot(self, execution_type=None, **kwargs):
        """
        Reboots a hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.PACKAGE)
    def install(self, execution_type=None, resource=None, **kwargs):
        """
        Installs the packages on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type resource: list
        @param resource: List of resources to be passed in to execute the
            operation by the method.
        """
        pass

    @auto_resolve(labels.PACKAGE)
    def configure_package(self, execution_type=None, operation=None,
                          resource=None, **kwargs):
        """
        Configures the packages on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type operation: list
        @param operation: List of operations that can be performed while
            configuring the package.
        @type resource: list
        @param resource: List of resources to be passed in to execute the
            operation by the method.
        """
        pass

    @auto_resolve(labels.PACKAGE)
    def update(self, execution_type=None, resource=None, **kwargs):
        """
        Updates the packages on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type resource: list
        @param resource: List of resources to be passed in to execute the
            operation by the method.
        """
        pass

    @auto_resolve(labels.PACKAGE)
    def uninstall(self, execution_type=None, resource=None, **kwargs):
        """
        Uninstalls the packages on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type resource: list
        @param resource: List of resources to be passed in to execute the
            operation by the method.
        """
        pass

    @auto_resolve(labels.PACKAGE)
    def are_installed(self, execution_type=None, packages=None, **kwargs):
        """
        Verifies the package installation on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type packages: list
        @param packages: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.SWITCH)
    def get_arp_table(self, execution_type=None, switch_id=None, **kwargs):
        """Get the arp table for the specific switch_id."""
        pass

    @auto_resolve(labels.SWITCH)
    def get_mac_table(self, execution_type=None, switch_id=None, **kwargs):
        """Get the mac table for the specific switch_id."""

    @auto_resolve(labels.SWITCH)
    def get_vtep_table(self, execution_type=None, switch_id=None, **kwargs):
        """Get the vtep table for the specific switch_id."""

    @auto_resolve(labels.POWER)
    def async_reboot(self, execution_type=None, **kwargs):
        """Performs an asynchronous reboot."""
        pass

    @auto_resolve(labels.HYPERVISOR)
    def update_pci_passthru(self, execution_type=None, config=None, **kwargs):
        """Updates pci passthru configuration."""
        pass

    @auto_resolve(labels.HYPERVISOR)
    def disconnect_host(self, execution_type=None, **kwargs):
        """Disconnect host."""
        pass

    @auto_resolve(labels.ADAPTER)
    def list_vnic(self, execution_type=None, **kwargs):
        """Lists hypervisor's vnic."""
        pass

    @auto_resolve(labels.ADAPTER)
    def list_pnic(self, execution_type=None, **kwargs):
        """Lists hypervisor's pnic."""
        pass

    @auto_resolve(labels.ADAPTER)
    def remove_vnic(self, execution_type=None, **kwargs):
        """Remove hypervisor's vnic."""
        pass

    @auto_resolve(labels.SERVICE)
    def start_service(self, execution_type=None, service_name=None, **kwargs):
        """Starts the service."""
        pass

    @auto_resolve(labels.SERVICE)
    def stop_service(self, execution_type=None, service_name=None, **kwargs):
        """Stops the service."""
        pass

    @auto_resolve(labels.SERVICE)
    def restart_service(self, execution_type=None, service_name=None,
                        **kwargs):
        """Restarts the service."""
        pass

    @auto_resolve(labels.SERVICE)
    def is_service_running(self, execution_type=None, service_name=None,
                           **kwargs):
        """Checks if the service is running"""
        pass

    @auto_resolve(labels.SERVICE)
    def get_individual_service_status(self, execution_type=None,
                                      service_name=None, **kwargs):
        """Returns the status of the given service"""
        pass

    @auto_resolve(labels.SERVICE)
    def get_service_status(self, execution_type=None, service_names=None,
                           **kwargs):
        """Returns the status of the given services"""
        pass

    @auto_resolve(labels.SERVICE)
    def uninstall_service(self, execution_type=None, service_name=None,
                          **kwargs):
        """Uninstalls the service."""
        pass

    @auto_resolve(labels.SERVICE)
    def update_service_policy(self, execution_type=None, service_name=None,
                              **kwargs):
        """Updates the service activation policy."""
        pass

    @auto_resolve(labels.SERVICE)
    def refresh_services(self, execution_type=None, **kwargs):
        """Refreshes hypervisor service information and settings."""
        pass

    @auto_resolve(labels.NETWORK)
    def list_networks(self, execution_type=None, **kwargs):
        """Lists the networks on the hypervisor."""
        pass

    @auto_resolve(labels.NSX)
    def get_controller(self, execution_type=None, **kwargs):
        """Get vsm controller in host"""
        pass

    @auto_resolve(labels.SWITCH)
    def get_logical_switch(self, execution_type=None, **kwargs):
        """Get the information for logical switches"""
        pass

    @auto_resolve(labels.FIREWALL)
    def configure_firewall(self, execution_type=None, firewall_status=None,
                           **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def configure_firewall_rule(self, execution_type=None, rule_operation=None,
                                **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def get_global_firewall_status(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def enable_global_firewall(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def disable_global_firewall(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def add_firewall_rule(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def delete_firewall_rule(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def list_firewall_rules(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def enable_firewall_ruleset(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def disable_firewall_ruleset(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def get_firewall_ruleset_status(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def set_nsx_registration(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def set_nsx_manager(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP, execution_type=constants.ExecutionType.CLI)
    def remove_nsx_manager(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def set_nsx_controller(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def setup_3rd_party_library(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SERVICE)
    def configure_service_state(self, execution_type=None,
                                service_name=None,  state=None, **kwargs):
        pass

    @auto_resolve(labels.SERVICE)
    def kill_service(self, execution_type=None, key=None, **kwargs):
        """Kills the service."""
        pass

    # TODO (miriyalak/gjayavelu): Why default execution_type in method
    # signature is not working?
    @auto_resolve(labels.CRUD, execution_type=constants.ExecutionType.CLI)
    def get_id(self, execution_type=None, **kwargs):
        """Get unique ID of the host"""
        pass

    @auto_resolve(labels.CRUD, execution_type=constants.ExecutionType.CLI)
    def get_system_id(self, execution_type=None, **kwargs):
        """Get unique system ID of the host"""
        pass

    @auto_resolve(labels.SWITCH)
    def set_switch_mtu(self, execution_type=None, value=None, vmnic_name=None,
                       **kwargs):
        """Configures mtu on the switch."""
        pass

    @auto_resolve(labels.SWITCH)
    def get_switch_mtu(self, execution_type=None, vmnic_name=None, **kwargs):
        """Get mtu on the switch."""
        pass

    def get_mgmt_ip(self):
        """Returns the management IP."""
        return self.ip

    @auto_resolve(labels.PORT)
    def get_port_qos_info(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PORT)
    def get_port_teaming_info(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.OS)
    def get_tcp_connection_count(self, execution_type=None, ip_address=None,
                                 port=None, connection_states=None,
                                 keywords=None, **kwargs):
        """
        Returns number of connections matching the criteria defined by
        given parameters.
        """
        pass

    @auto_resolve(labels.OS)
    def replace_regex_in_file(self, execution_type=None,
                              path=None, find=None,
                              replace=None, first=False, **kwargs):
        """
        Replaces a string in the file based on regular
        expression or absolute match
        """
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adapter_info(self, execution_type=None, **kwargs):
        """Returns the info about all adapters on the host."""
        pass

    @auto_resolve(labels.NSX)
    def get_tunnel_ports_remote_ip(self, execution_type=None, **kwargs):
        """Returns list of remote ips associated with all tunnel ports."""
        pass

    @auto_resolve(labels.ROUTER)
    def disconnect_vdr_port_from_switch(self, execution_type=None, **kwargs):
        """Disconnect vdr port from switch"""
        pass

    @auto_resolve(labels.SWITCH)
    def delete_vdr_port(self, execution_type=None, **kwargs):
        """Delete vdr port from nsxvswitch."""

    @auto_resolve(labels.FILEOPS)
    def syslog_append(self, execution_type=None, syslog_message=None,
                      **kwargs):
        """Write a message to the syslog"""
        pass

    @auto_resolve(labels.FILEOPS)
    def file_append(self, execution_type=None, file_name=None,
                    append_string=None, size=None):
        """Append a string to a file"""
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

    @auto_resolve(labels.FILEOPS)
    def find_pattern_count(cls, client_object, file_name=None,
                           grep_string=None, grep_after=None,
                           pattern=None, **kwargs):
        """Count number of patterns in file """
        pass

    @auto_resolve(labels.MESSAGING)
    def read_client_token(self, execution_type=None, **kwargs):
        """Helper method to return the account name/client-token as a k,v pair
        to persist across workloads"""
        pass

    @auto_resolve(labels.MESSAGING)
    def read_master_broker_ip(self, execution_type=None, **kwargs):
        """Read master broker ip of a host - DEPRECATED"""
        pass

    @auto_resolve(labels.MESSAGING)
    def read_broker_ip(self, execution_type=None, **kwargs):
        """Helper method to return the broker ip as a k,v pair to persist
        across workloads"""
        pass

    @auto_resolve(labels.MESSAGING)
    def read_broker_port(self, execution_type=None, num=0, **kwargs):
        """Helper method to return the broker port as a k,v pair to persist
        across workloads"""
        pass

    @auto_resolve(labels.MESSAGING)
    def read_broker_thumbprint(self, execution_type=None, num=0, **kwargs):
        """Helper method to return the broker thumbprint as a k,v pair to
        persist across workloads"""
        pass

    @auto_resolve(labels.MESSAGING)
    def remove_broker(self, execution_type=None, **kwargs):
        """
        Remove a broker from the mpa config file by ip address or entry number
        """
        pass

    @auto_resolve(labels.MESSAGING)
    def add_broker(self, execution_type=None, num=0, ip=None, port='5671',
                   virtual_host='nsx', thumbprint=None, master=False,
                   **kwargs):
        """
        Add a broker to the mpa config file
        """
        pass

    @auto_resolve(labels.MESSAGING)
    def get_client_token(self, execution_type=None, **kwargs):
        """Read the mpaconfig and get the account name/client-token """
        pass

    @auto_resolve(labels.MESSAGING)
    def get_broker_ip(self, execution_type=None, num=0, **kwargs):
        """ Read the mpaconfig and get the broker ip """
        pass

    @auto_resolve(labels.MESSAGING)
    def get_broker_port(self, execution_type=None, num=0, **kwargs):
        """ Read the mpaconfig and get the broker port """
        pass

    @auto_resolve(labels.MESSAGING)
    def get_broker_thumbprint(self, execution_type=None, num=0, **kwargs):
        """ Read the mpaconfig and get the broker thumbprint """
        pass

    @auto_resolve(labels.MESSAGING)
    def connect_sample_client(self, execution_type=None, host_ip=None,
                              name=None, **kwargs):
        """ test connect sample client server"""
        pass

    @auto_resolve(labels.MESSAGING)
    def vertical_registration(self, execution_type=None, host_ip=None,
                              application_type=None, application_id=None,
                              client_type=None, registration_options=None,
                              **kwargs):
        """ configure sample client vertical registration"""
        pass

    @auto_resolve(labels.MESSAGING)
    def vertical_close_connection(self, execution_type=None,
                                  host_ip=None, cookieid=None, **kwargs):
        """ test sample vertical close connection"""
        pass

    @auto_resolve(labels.SERVICE)
    def sample_client(self, execution_type=None,
                      application_type=None,
                      application_id=None,
                      interactive_mode=None,
                      demo_mode=None,
                      expected_output=None,
                      **kwargs):
        """start up mpa sample_client application"""
        pass

    @auto_resolve(labels.PROCESSES)
    def kill_processes_by_name(self, execution_type=None, options=None,
                               process_name=None, **kwargs):
        """Kill all processes by name"""
        pass

    @auto_resolve(labels.PROCESSES)
    def get_pid(self, execution_type=None, process_name=None, **kwargs):
        """Get PID of the process"""
        pass

    @auto_resolve(labels.PROCESSES)
    def get_process_status(self, execution_type=None, process_name=None,
                           **kwargs):
        """Get status of the process"""
        pass

    @auto_resolve(labels.SERVICE)
    def verify_broker_num_clients(self, execution_type=None,
                                  num_clients=None, **kwargs):
        """Check number of clients connected to cluster"""
        pass

    @auto_resolve(labels.SERVICE)
    def fetch_endpoint_testrpc(self, execution_type=None, master=True,
                               pre_sleep=0, **kwargs):
        """Call the RestAPI testrpc endpoint via curl"""
        pass

    @auto_resolve(labels.VM)
    def fetch_moid_from_ip(cls, vm_ip_address=None, **kwargs):
        """
        Returns the MOID value given the ip_address of any
        virtual machine
        """
        pass

    @auto_resolve(labels.VM)
    def fetch_vm_mor_from_name(cls, vm_name=None, **kwargs):
        """
        Returns the MOID value given the vm name of any
        virtual machine
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def download_files(self, execution_type=None, resource=None,
                       destination=None, **kwargs):
        """
        Download files onto a host, specifying in target pairs a
        source and destination for each file
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def remove_file(cls, client_object, options=None,
                    file_name=None, timeout=None):
        """
        Remove files from the host
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def get_dict_from_json_file(cls, execution_type=None, file_name=None,
                                **kwargs):
        """
        Save a file as a dict
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def move_file(cls, execution_type=None, source_path=None,
                  destination_path=None, file_name=None,
                  dest_file_name=None, **kwargs):
        """
        Move a file from one location to another
        """
        pass

    @auto_resolve(labels.NSX)
    def get_ipfix_config(cls, execution_type=None, **kwargs):
        """
        Returns the IPFIX configuration from the host.
        """
        pass

    @auto_resolve(labels.ADAPTER)
    def get_pnics(cls, execution_type=None, **kwargs):
        """
        Returns the list of pnics on the client
        """
        pass

    @auto_resolve(labels.NETWORK)
    def get_dvpg_id_from_name(cls, execution_type=None,
                              dvs=None, dvpg=None, **kwargs):
        """
        Returns the ID(Key) of the dvpg present on the DVSwitch(dvs)
        """
        pass

    @auto_resolve(labels.HYPERVISOR)
    def get_host_uuid(cls, execution_type=None, **kwargs):
        """
        Returns host uuid using nsxcli 'show host uuid'
        """

    @auto_resolve(labels.ADAPTER)
    def get_vtep_detail(self, execution_type=None, **kwargs):
        """
        Returns vxlan vtep detail list on hypervisor.
        """
    @auto_resolve(labels.MESSAGING)
    def vertical_send_msg(self, execution_type=None, host_ip=None,
                          test_params=None, count=1, cookie_id=None,
                          msg_type=None, **kwargs):
        """ test sample vertical send message"""
        pass

    # TODO Deprecate once kvm refactor is done
    @auto_resolve(labels.MESSAGING)
    def vertical_send_generic_msg(self, execution_type=None, host_ip=None,
                                  amqp_payload=None, count=1,
                                  cookieid=None, **kwargs):
        """ test sample vertical send generic message"""
        pass

    # TODO Deprecate once kvm refactor is done
    @auto_resolve(labels.MESSAGING)
    def vertical_send_rpc_msg(self, execution_type=None, host_ip=None,
                              amqp_payload=None, count=1,
                              cookieid=None, **kwargs):
        """ test sample vertical send rpc message"""
        pass

    # TODO Deprecate once kvm refactor is done
    @auto_resolve(labels.MESSAGING)
    def vertical_send_publish_msg(self, execution_type=None, host_ip=None,
                                  amqp_payload=None, count=1,
                                  cookieid=None, **kwargs):
        """ test sample vertical send publish message"""
        pass

    @auto_resolve(labels.VM)
    def get_vm_list(self, execution_type=None, **kwargs):
        """Gets the list of VMs present on the hypervisor"""
        pass

    @auto_resolve(labels.VM)
    def get_vm_list_by_attribute(self, execution_type=None,
                                 attribute=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def install_nsx_components(self, execution_type=None, credential=None,
                               host_id=None, **kwargs):
        """Perform service deployment prepare operation on host node"""
        pass

    @auto_resolve(labels.SETUP)
    def uninstall_nsx_components(self, execution_type=None, credential=None,
                                 host_id=None, **kwargs):
        """Perform service deployment unprepare operation on host node"""
        pass

    # ------------------ ROUTER INTERFACE [AUTOGENERATED] ----------------- #
    @auto_resolve(labels.ROUTER)
    def get_logical_router_ports(
            self, execution_type=None, logical_router_id=None, **kwargs):
        """ get all logical router port data on logical router"""
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_port_info(
            self, execution_type=None, logical_router_id=None, port_id=None,
            **kwargs):
        """ get data for a given port on logical router"""
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_id(
            self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_routers(
            self, execution_type=None, **kwargs):
        """ get all logical router data"""
        pass

    @auto_resolve(labels.ROUTER)
    def get_route_table(
            self, execution_type=None, logical_router_id=None, **kwargs):
        """ get routing table of a logical router"""
        pass

    @auto_resolve(labels.ROUTER)
    def get_dr_arp_table(
            self, execution_type=None, logical_router_id=None, port_id=None,
            **kwargs):
        """ get arp table for the DR of logical router"""
        pass

    @auto_resolve(labels.ROUTER)
    def read_next_hop(
            self, execution_type=None, logical_router_id=None,
            source_ip=None, destination_ip=None, **kwargs):
        """ get next hop from DR for given src/dest ips """
        pass

    @auto_resolve(labels.OS)
    def set_hostname(cls, execution_type=None, hostname=None, **kwargs):
        """
        Set the given hostname and return command status
        """
        pass

    @auto_resolve(labels.OS)
    def read_hostname(cls, execution_type=None, **kwargs):
        """
        Returns hostname
        """
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_node_status(self, execution_type=None, **kwargs):
        """
        Get the status for a given host node as reported by aggregation
        service.
        """
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_node_interfaces(self, execution_type=None, **kwargs):
        """
        Get the information of host node interfaces as reported by
        aggregation service.
        """
        pass
