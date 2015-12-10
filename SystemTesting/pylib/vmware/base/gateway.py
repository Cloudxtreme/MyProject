import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Gateway(base.Base):

    def __init__(self, name=None, parent=None, ip=None, username=None,
                 password=None, build=None):
        super(Gateway, self).__init__()
        self.name = name
        self.parent = parent
        self.ip = ip
        self.username = username
        self.password = password
        self.build = build

    @auto_resolve(labels.SETUP)
    def register_nsx_edge_node(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def show_interface(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.VM)
    def get_cpu_count(self, execution_type=None,
                      vm_ip_address=None, **kwargs):
        """
        Verifies the CPU COUNT for given VM IP Addr
        """
        pass

    @auto_resolve(labels.VM)
    def get_nic_count(self, execution_type=None,
                      vm_ip_address=None, **kwargs):
        """
        Verifies the NIC COUNT for given VM IP Addr
        """
        pass

    @auto_resolve(labels.VM)
    def get_virtual_disk_count(self, execution_type=None,
                               vm_ip_address=None, **kwargs):
        """
        Verifies the VIRTUAL DISK COUNT for given VM IP Addr
        """
        pass

    @auto_resolve(labels.VM)
    def get_mem_size(self, execution_type=None,
                     vm_ip_address=None, **kwargs):
        """
        Verifies the MEMORY SIZE for given VM IP Addr
        """
        pass

    @auto_resolve(labels.VM)
    def get_disk_size(self, execution_type=None,
                      vm_ip_address=None, disk_index=None, **kwargs):
        """
        Verifies the DISK SIZE for given VM IP Addr amd
        disk_index for the same
        """
        pass

    @auto_resolve(labels.VM)
    def get_nic_type(self, execution_type=None,
                     vm_ip_address=None, vnic_index=None, **kwargs):
        """
        Verifies the NIC TYPE for given VM IP Addr amd
        vnic_index for the same
        """
        pass

    @auto_resolve(labels.VM)
    def get_max_memory_usage(self, execution_type=None,
                             vm_ip_address=None, **kwargs):
        """
        Verifies the MAX MEMORY value for given VM IP Addr
        """
        pass

    @auto_resolve(labels.VM)
    def get_max_cpu_usage(self, execution_type=None,
                          vm_ip_address=None, **kwargs):
        """
        Verifies the MAX CPU value for given VM IP Addr
        """
        pass

    @auto_resolve(labels.CLUSTER)
    def get_cluster_status(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CLUSTER)
    def get_member_index(self):
        pass

    @auto_resolve(labels.VM)
    def get_tools_running_status(self, execution_type=None,
                                 vm_ip_address=None, **kwargs):
        """
        Verifies the VMTools Running Status for given VM
        """
        pass

    @auto_resolve(labels.OS)
    def get_os_info(self, execution_type=None, **kwargs):
        """
        Returns the Kernel version, Build number, Name and Version
        information for given NSX edge
        """
        pass

    @auto_resolve(labels.OS)
    def get_license_string(self, execution_type=None, **kwargs):
        """
        Returns the License Agreement information for given NSX edge
        """
        pass

    @auto_resolve(labels.OS)
    def get_all_supported_commands_admin_mode(
            self, execution_type=None, **kwargs):
        """
        Logs in to NSXEdge in admin mode and fetches the list of
        all supported commands for given NSX edge
        """
        pass

    @auto_resolve(labels.OS)
    def get_all_supported_commands_enable_mode(
            self, execution_type=None, **kwargs):
        """
        Logs in to NSXEdge in enable mode and fetches the list of
        all supported commands for given NSX edge
        """
        pass

    @auto_resolve(labels.OS)
    def get_all_supported_commands_configure_mode(
            self, execution_type=None, **kwargs):
        """
        Logs in to NSXEdge in configure mode and fetches the list of
        all supported commands for given NSX edge
        """
        pass

    @auto_resolve(labels.VM)
    def get_nic_status(self, execution_type=None,
                       vm_ip_address=None, vnic_index=None, **kwargs):
        """
        Verifies the NIC STATUS for given VM IP Addr amd
        vnic_index for the same
        """
        pass

    @auto_resolve(labels.ADAPTER)
    def get_assigned_interface_ip(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CLUSTER)
    def get_cluster_history_resource(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CLUSTER)
    def get_cluster_history_state(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.VM)
    def get_guest_net_info(self, execution_type=None,
                           vm_name=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_edge_interface_ip(self, execution_type=None, **kwargs):
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

    @auto_resolve(labels.ROUTER)
    def is_master_for_lr(
            self, execution_type=None, logical_router_id=None, **kwargs):
        """ check if a controller is master for given lrouter """
        pass

    @auto_resolve(labels.ROUTER)
    def get_ip(self, execution_type=None, **kwargs):
        """ get the table entries for (BGP/forwarding) """
        pass

    @auto_resolve(labels.ROUTER)
    def get_configuration_bgp(self, execution_type=None, **kwargs):
        """ get bgp configuration"""
        pass

    @auto_resolve(labels.ROUTER)
    def get_ip_route(self, execution_type=None, **kwargs):
        """ get ip route """
        pass

    @auto_resolve(labels.ROUTER)
    def get_ip_bgp_neighbors(self, execution_type=None, **kwargs):
        """ get bgp neighbors information """
        pass

    @auto_resolve(labels.ROUTER)
    def clear_ip_bgp(self, execution_type=None, **kwargs):
        """ clear bgp configuration """
        pass
