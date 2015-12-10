import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Controller(base.Base):
    def __init__(self, ip=None, username=None, password=None,
                 cmd_username=None, cmd_password=None, cert_thumbprint=None,
                 build=None):
        super(Controller, self).__init__()
        self.ip = ip
        self.username = username
        self.password = password
        self.cmd_username = cmd_username
        self.cmd_password = cmd_password
        self.cert_thumbprint = cert_thumbprint
        self.build = build

    @auto_resolve(labels.SWITCH)
    def get_arp_table(self, execution_type=None, switch_id=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_mac_table(self, execution_type=None, switch_id=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_vtep_table(self, execution_type=None, switch_id=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_vni_table(self, execution_type=None, switch_id=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_stats_table(self, execution_type=None, switch_id=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_connection_table(self, execution_type=None, switch_id=None,
                             **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def is_master_for_vni(self, execution_type=None, switch_vni=None,
                          **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def is_master_for_lr(self, execution_type=None, lr_id=None,
                         **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_routers(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_ports(self, execution_type=None,
                                 logical_router_id=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_route_table(self, execution_type=None,
                        logical_router_id=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_port_info(self, execution_type=None,
                                     logical_router_id=None, port_id=None,
                                     **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def set_nsx_registration(self, execution_type=None, manager_ip=None,
                             manager_thumbprint=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def clear_nsx_registration(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def remove_ccp_cluster_node(self, execution_type=None, controller_ip=None,
                                **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def set_security(self, execution_type=None, security_type=None,
                     value=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def get_control_cluster_thumbprint(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SETUP)
    def clear_controller(self, execution_type=None, **kwargs):
        pass

    def get_controller_ip(self):
        return self.ip

    @auto_resolve(labels.SWITCH)
    def get_logical_switches(self, execution_type=None, switches=None,
                             **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_entry_count(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.FIREWALL)
    def network_partitioning(self, execution_type=None, ip_address=None,
                             protocol=None, port=None, operation=None,
                             **kwargs):
        """
        Isolate target ip from current device
        @type ip_address: String
        @param ip_address: ip address of target that you want isolation,
                           could be controller_ip, manager_ip...
        @type protocol: String
        @param protocol: tcp/udp
        @type port: String
        @param port: port number
        @type operation: String
        @param operation: set/reset
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def delete_file(self, execution_type=None, file_name=None):
        pass

    @auto_resolve(labels.SERVICE)
    def configure_service_state(self, execution_type=None,
                                service_name=None, state=None, **kwargs):
        """
        Stop/Start/Restart services of CCP appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.TROUBLESHOOT)
    def copy_tech_support(self, execution_type=None, logdir=None,
                          collectorIP=None):
        pass

    @auto_resolve(labels.FIREWALL)
    def configure_firewall_rule(self, execution_type=None, rule_operation=None,
                                **kwargs):
        pass

    @auto_resolve(labels.POWER)
    def reboot(self, execution_type=None, **kwargs):
        """
        Restart the NSX Controller appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def verify_version(self, execution_type=None, **kwargs):
        """
        Verify the version of NSX Controller using show version command
        """
        pass

    @auto_resolve(labels.SWITCH)
    def get_full_sync_count(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_full_sync_diff(self, execution_type=None,
                           before_test_full_sync_count=None, **kwargs):
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_system_config(self, execution_type=None,
                          system_parameter=None, **kwargs):
        """
        Get the system memory of the NSX Controller using show
        system memory command
        Get the total cpus on the NSX Controller using
        show system cpu command
        Get the storage size on the NSX Controller using
        show system storage command
        Get the tx and rx packets on the NSX Controller using
        show system network-stats command
        The up-time of the system is valid, that is at-least one amongst the
        days, minutes or seconds, is greater than 0'
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def search_log(self, execution_type=None, **kwargs):
        """
        Run command on NSXManager, return output and check the
        desired string in the output
        """
        pass

    @auto_resolve(labels.FILEOPS)
    def delete_backend_file(self, execution_type=None, **kwargs):
        """
        Delete a file from backend on Controller.
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_configuration(self, execution_type=None, **kwargs):
        """
        Verify the IP Address of NSX Controller using show configuration
        command
        """
        pass

    @auto_resolve(labels.APPLIANCE)
    def show_interfaces(self, execution_type=None, **kwargs):
        """
        Verify the IP Address of NSX Controller using show interfaces command
        """
        pass

    @auto_resolve(labels.SERVICE)
    def get_service_status(self, execution_type=None,
                           service_names=None, **kwargs):
        """Returns the status of the given service"""
        pass

    @auto_resolve(labels.SETUP)
    def tunnel_process(self, execution_type=None, endpoints=None,
                       operation=None, **kwargs):
        """
        Kill/Check tunnel to other conntroller on controller
        @type endpoints: List
        @param endpoints: List of controller object, to get ip address
        @type operation: String
        @param operation: kill/check
        """
        pass
