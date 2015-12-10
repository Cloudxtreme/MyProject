import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class VM(base.Base):
    """VM base client."""

    def __init__(self, name=None, parent=None, ip=None, username=None,
                 password=None):
        super(VM, self).__init__()
        self.name = name
        self.parent = parent
        self.ip = ip
        self.username = username
        self.password = password

    @auto_resolve(labels.POWER)
    def on(self, execution_type=None, **kwargs):
        """Powers on a VM using the desired implementation."""
        pass

    @auto_resolve(labels.POWER)
    def off(self, execution_type=None, **kwargs):
        """Powers off a VM using the desired implementation."""
        pass

    @auto_resolve(labels.POWER)
    def reboot(self, execution_type=None, **kwargs):
        """Reboots a VM using the desired implementation."""
        pass

    @auto_resolve(labels.POWER)
    def shutdown(self, execution_type=None, **kwargs):
        """Shuts down a VM using the desired implementation."""
        pass

    @auto_resolve(labels.POWER)
    def reset(self, execution_type=None, **kwargs):
        """ Resets a VM using the desired implementation."""
        pass

    @auto_resolve(labels.POWER)
    def get_power_state(self, execution_type=None, **kwargs):
        """Returns the client's current power state."""
        pass

    @auto_resolve(labels.VM)
    def suspend(self, execution_type=None, **kwargs):
        """Suspends the VM using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def create_snapshot(self, execution_type=None, name=None,
                        description=None, **kwargs):
        """Creates a VM snapshot using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def remove_snapshot(self, execution_type=None,
                        vm_snapshot=None, remove_children=False, **kwargs):
        """Removes a snapshot of the VM using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def revert_to_current_snapshot(self, execution_type=None,
                                   host=None, **kwargs):
        """Reverts VM to current snapshot using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def revert_to_snapshot(self, execution_type=None,
                           vm_snapshot=None, host=None, **kwargs):
        """Reverts VM to given snapshot using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def upgrade_tools(self, execution_type=None,
                      installer_options=None, **kwargs):
        """Upgrades tools using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def mount_tools_installer(self, execution_type=None, **kwargs):
        """Mounts tools using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def unmount_tools_installer(self, execution_type=None, **kwargs):
        """Unmounts tools using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def register_vm(self, execution_type=None,
                    path=None, name=None, **kwargs):
        """Registers VM in the inventory using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def unregister_vm(self, execution_type=None, **kwargs):
        """Unregisters VM from inventory using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def get_vm_spec_path(self, execution_type=None, **kwargs):
        """Queries for the vm file path using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def get_guest_info(self, execution_type=None, **kwargs):
        """Queries guest OS information using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def get_guest_net_info(self, execution_type=None, **kwargs):
        """Queries VM network information using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def get_vm_hardware_info(self, execution_type=None, **kwargs):
        """Queries VM hardware information using the desired implementation."""
        pass

    @auto_resolve(labels.VM)
    def check_device_connection_status(self, execution_type=None,
                                       device_name=None, **kwargs):
        """Checks the connection status of the specified device"""
        pass

    @auto_resolve(labels.VM)
    def check_tools_mounting_status(self, execution_type=None, **kwargs):
        """Checks the status of the tools"""
        pass

    @auto_resolve(labels.VM)
    def configure_pci_passthrough(self, execution_type=None, **kwargs):
        """Configures passthrough for the guest"""

    @auto_resolve(labels.APPLIANCE)
    def get_management_mac(cls, execution_type=None, **kwargs):
        """ Method to get_management_mac of this vm. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_management_ip(cls, execution_type=None, **kwargs):
        """ Method to get_management_ip of this vm. """
        pass

    @auto_resolve(labels.APPLIANCE)
    def get_management_ipv6(cls, execution_type=None, **kwargs):
        """ Method to get IPv6 address of management interface of this vm. """
        pass

    @auto_resolve(labels.ADAPTER)
    def delete_all_test_adapters(cls, execution_type=None, **kwargs):
        """ Deletes all test adapters from the entity. """
        pass

    @auto_resolve(labels.VM)
    def get_name(self, execution_type=None, **kwargs):
        """Get The name of Vm"""
        pass

    @auto_resolve(labels.VM)
    def rename_vm(self, execution_type=None, name=None, **kwargs):
        """Rename vm"""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def configure_dhcp_server(self, execution_type=None, **kwargs):
        """Configures a DHCP Server with desired parameters."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def enable_dhcp_server_on_interfaces(self, execution_type=None, **kwargs):
        """Enables DHCP Server on an interface."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def setup_dhcp_server(self, execution_type=None, **kwargs):
        """Initial set up of DHCP Server using dhcpd.conf."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def restart_dhcp_server(self, execution_type=None, **kwargs):
        """ Resets a DHCP Server."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def stop_dhcp_server(self, execution_type=None, **kwargs):
        """Stops the DHCP Server."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def start_dhcp_server(self, execution_type=None, **kwargs):
        """Starts the DHCP Server."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def disable_dhcp_server_on_interfaces(self, execution_type=None, **kwargs):
        """Disables DHCP Server on an interface."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def clear_dhcp_server_config(self, execution_type=None, **kwargs):
        """Clear DHCP Server configuration."""
        pass

    @auto_resolve(labels.DHCPSERVER)
    def install_dhcp_server(self, execution_type=None, **kwargs):
        """Installs a DHCP Server."""
        pass

    @auto_resolve(labels.OS)
    def ip_route(self, execution_type=None, **kwargs):
        """Configures routes on DHCP Server."""
        pass

    @auto_resolve(labels.OS)
    def empty_file_contents(self, execution_type=None, **kwargs):
        """Empty file contents."""
        pass

    @auto_resolve(labels.OS)
    def append_file(self, execution_type=None, **kwargs):
        """Append contents to a file."""
        pass

    @auto_resolve(labels.OS)
    def replace_regex_in_file(self, execution_type=None, **kwargs):
        """Replace matched string in a file."""
        pass

    @auto_resolve(labels.PACKAGE)
    def update(self, execution_type=None, **kwargs):
        """Update a package."""
        pass

    @auto_resolve(labels.PACKAGE)
    def install(self, execution_type=None, **kwargs):
        """Install a package."""

    @auto_resolve(labels.VM)
    def get_mem_size(self, execution_type=None, **kwargs):
        """Get Memory Size of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_cpu_count(self, execution_type=None, **kwargs):
        """Get CPU Count of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_nic_count(self, execution_type=None, **kwargs):
        """Get NIC Count of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_virtual_disk_count(self, execution_type=None, **kwargs):
        """Get Virtual Disk Count of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_max_memory_usage(self, execution_type=None, **kwargs):
        """Get Max Memory Usage of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_max_cpu_usage(self, execution_type=None, **kwargs):
        """Get Max CPU Usage of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_nic_type(self, execution_type=None,
                     **kwargs):
        """Get NIC Type of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_disk_size(self, execution_type=None,
                      disk_index=None, **kwargs):
        """Get DISK SIZE of Vm"""
        pass

    @auto_resolve(labels.VERIFICATION)
    def start_capture(self, tool=None, **kwargs):
        """Starts the capture process."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def stop_capture(self, tool=None, **kwargs):
        """Stops the capture process."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def extract_capture_results(self, tool=None, **kwargs):
        """Extracts the captured data."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def get_ipfix_capture_data(self, tool=None, **kwargs):
        """Gets IPFIX capture data."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def get_capture_data(self, tool=None, **kwargs):
        """Gets captured traffic data using a user specified tool."""
        pass

    @auto_resolve(labels.PROCESSES)
    def kill_processes_by_name(self, execution_type=None, process_name=None,
                               **kwargs):
        """Kill all processes by name."""
        pass

    @auto_resolve(labels.OS)
    def configure_arp_entry(self, destination_ip=None, **kwargs):
        """Configures arp entry on the VM."""
        pass

    @auto_resolve(labels.OS)
    def get_iface(self, mac=None, **kwargs):
        """Get Iface information from the VM."""
        pass

    @auto_resolve(labels.OS, execution_type=constants.ExecutionType.CMD)
    def get_ipcidr(self, **kwargs):
        pass

    @auto_resolve(labels.VM)
    def get_tools_running_status(self, execution_type=None,
                                 **kwargs):
        """Get VM Tools Running status of Vm"""
        pass

    @auto_resolve(labels.VM)
    def get_nic_status(self, execution_type=None, **kwargs):
        """Get NIC Status of Vm"""
        pass

    @auto_resolve(labels.VERIFICATION)
    def get_captured_packet_count(self, tool=None, **kwargs):
        """Gets captured packet count."""
        pass

    @auto_resolve(labels.ADAPTER)
    def get_single_adapter_info(self, execution_type=None, adapter_ip=None,
                                adapter_name=None, **kwargs):
        """Discovers an adapter based on adapter's name or IP."""

    @auto_resolve(labels.VM)
    def wait_for_guest_state(self, execution_type=None, **kwargs):
        """Waits until the guest is in the specified state."""
        pass

    @auto_resolve(labels.VM)
    def check_device_attach_state(self, execution_type=None,
                                  device=None, **kwargs):
        """Checks if the device is present on the VM"""
        pass

    @auto_resolve(labels.VM)
    def check_if_vm_exists(self, execution_type=None, **kwargs):
        """Checks if the VM exists in the inventory"""
        pass

    @auto_resolve(labels.OS)
    def start_ncat_server(self, execution_type=None, **kwargs):
        """Starts an ncat listening process"""
        pass

    @auto_resolve(labels.OS)
    def start_netcat_server(self, execution_type=None, **kwargs):
        """Starts a netcat listening process"""
        pass
