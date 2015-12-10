class VMInterface(object):
    """Interface class to implement client related operations."""

    @classmethod
    def suspend(cls, client_object):
        """Interface to perform suspend operation on the client."""
        raise NotImplementedError

    @classmethod
    def create_snapshot(cls, client_object,
                        name=None, description=None, **kwargs):
        """Interface to create snapshot of the client."""
        raise NotImplementedError

    @classmethod
    def remove_snapshot(cls, client_object, snapshot_name=None,
                        remove_children=False, **kwargs):
        """Interface to remove the client snapshot from the inventory."""
        raise NotImplementedError

    @classmethod
    def revert_to_current_snapshot(cls, client_object,
                                   host=None, **kwargs):
        """Interface to revert client state to current snapshot."""
        raise NotImplementedError

    @classmethod
    def revert_to_snapshot(cls, client_object,
                           snapshot_name=None, host=None, **kwargs):
        """Interface to revert client state to given snapshot."""
        raise NotImplementedError

    @classmethod
    def upgrade_tools(cls, client_object,
                      installer_options=None, **kwargs):
        """Interface to upgrade tools."""
        raise NotImplementedError

    @classmethod
    def mount_tools_installer(cls, client_object, **kwargs):
        """Interface to mount tools."""
        raise NotImplementedError

    @classmethod
    def unmount_tools_installer(cls, client_object, **kwargs):
        """Interface to unmount tools."""
        raise NotImplementedError

    @classmethod
    def register_vm(cls, client_object, path=None,
                    name=None, **kwargs):
        """Interface to register a client in the inventory."""
        raise NotImplementedError

    @classmethod
    def unregister_vm(cls, client_object, **kwargs):
        """Interface to unregister a client from the inventory."""
        raise NotImplementedError

    @classmethod
    def get_vm_spec_path(cls, client_object, **kwargs):
        """Interface to get vm file path."""
        raise NotImplementedError

    @classmethod
    def get_guest_info(cls, client_object, **kwargs):
        """Interface to get client guest OS info."""
        raise NotImplementedError

    @classmethod
    def get_guest_net_info(cls, client_object, **kwargs):
        """Interface to get client guest OS network info."""
        raise NotImplementedError

    @classmethod
    def get_vm_hardware_info(cls, client_object, **kwargs):
        """Interface to get client hardware info."""
        raise NotImplementedError

    @classmethod
    def resume(cls, client_object, **kwargs):
        """Interface to resume the client."""
        raise NotImplementedError

    @classmethod
    def check_device_connection_status(cls, client_object,
                                       device_name=None, **kwargs):
        """Checks the connection status of the specified device."""
        raise NotImplementedError

    @classmethod
    def check_tools_mounting_status(cls, client_object, **kwargs):
        """Checks the status of tools installed"""
        raise NotImplementedError

    @classmethod
    def configure_pci_passthrough(cls, client_object, **kwargs):
        """Configures pci passthrough"""
        raise NotImplementedError

    @classmethod
    def get_name(cls, client_object, **kwargs):
        """Get name"""
        raise NotImplementedError

    @classmethod
    def rename_vm(cls, client_object, name=None, **kwargs):
        """Rename name"""
        raise NotImplementedError

    @classmethod
    def get_mem_size(cls, client_object, **kwargs):
        """Get MEMORY SIZE"""
        raise NotImplementedError

    @classmethod
    def get_cpu_count(cls, client_object, **kwargs):
        """Get CPU Count"""
        raise NotImplementedError

    @classmethod
    def get_nic_count(cls, client_object, **kwargs):
        """Get NIC Count"""
        raise NotImplementedError

    @classmethod
    def get_virtual_disk_count(cls, client_object, **kwargs):
        """Get Virtual Disk Count"""
        raise NotImplementedError

    @classmethod
    def get_max_cpu_usage(cls, client_object, **kwargs):
        """Get Max CPU Usage"""
        raise NotImplementedError

    @classmethod
    def get_max_memory_usage(cls, client_object, **kwargs):
        """Get Max Memory Usage"""
        raise NotImplementedError

    @classmethod
    def get_nic_type(cls, client_object, nic_index=None, **kwargs):
        """Get NIC Type"""
        raise NotImplementedError

    @classmethod
    def get_disk_size(cls, client_object, disk_index=None, **kwargs):
        """Get Disk Size"""
        raise NotImplementedError

    @classmethod
    def fetch_moid_from_ip(cls, client_object, vm_ip_address=None, **kwargs):
        """
        Interface to fetch MOID value given the ip_address of any
        virtual machine
        """
        raise NotImplementedError

    @classmethod
    def fetch_vm_mor_from_name(cls, client_object, vm_name=None, **kwargs):
        """
        Interface to fetch MOID value given the vm name of any
        virtual machine
        """
        raise NotImplementedError

    @classmethod
    def get_tools_running_status(cls, client_object, **kwargs):
        """Get VM Tools Running status of Vm"""
        raise NotImplementedError

    @classmethod
    def get_nic_status(cls, client_object, nic_index=None, **kwargs):
        """Get NIC Status"""
        raise NotImplementedError

    @classmethod
    def wait_for_guest_state(cls, client_object, **kwargs):
        """Waits until the guest is in the specified state."""
        raise NotImplementedError

    @classmethod
    def check_device_attach_state(cls, client_object, device=None, **kwargs):
        """Checks if the device is present on the VM."""
        raise NotImplementedError

    @classmethod
    def check_if_vm_exists(cls, client_object, **kwargs):
        """Checks if the VM exists in the inventory."""
        raise NotImplementedError

    @classmethod
    def get_vm_list(cls, client_object, **kwargs):
        """Gets the list of VMs present on the client."""
        raise NotImplementedError

    @classmethod
    def get_vm_list_by_attribute(cls, client_object,
                                 attribute=None, **kwargs):
        raise NotImplementedError
