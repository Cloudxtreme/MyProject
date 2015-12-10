import vmware.interfaces.vm_interface as vm_interface
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ESX55VMImpl(vm_interface.VMInterface):
    """Hypervisor related VM operations."""

    @classmethod
    def fetch_moid_from_ip(cls, client_object, vm_ip_address=None):
        """
        Returns the MOID value given the ip_address of any
        virtual machine

        The method uses the ESX managed object reference to
        extract the MOID value for given IP.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Status of the operation
        """
        host_mor = client_object.get_host_mor()
        for vm in host_mor.vm:
            if vm.guest.ipAddress == vm_ip_address:
                return str(vm._moId).split(".")[-1]
        raise Exception("%s vm not found for the ip address " %
                        vm_ip_address)

    @classmethod
    def fetch_vm_mor_from_name(cls, client_object, vm_name=None):
        """
        Returns the MOID value given the vm name of any
        virtual machine

        The method uses the ESX managed object reference to
        extract the MOID value for given name.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Status of the operation
        """
        host_mor = client_object.get_host_mor()
        for vm in host_mor.vm:
            if vm.name == vm_name:
                return str(vm._moId).split(".")[-1]
        raise Exception("%s vm not found for the vm name " %
                        vm_name)

    @classmethod
    def get_vm_list(cls, client_object):
        """
        Gets all the VM managed objects present on the client

        @type client_object: ESXAPIClient instance
        @param client_object: ESXAPIClient instance

        @rtype: list
        @return: list of vim.VirtualMachine instance
        """
        host_mor = client_object.get_host_mor()
        return host_mor.vm

    @classmethod
    def get_vm_list_by_attribute(cls, client_object,
                                 attribute=None, attribute_list=None):
        """
        Gets a list of VMs based on the attribute information

        The method retrieves a list of vim.VirtualMachine objects
        based on the attribute given, and an attribute list which
        could be either a list of VM names, or a list of VMX paths.

        @type client_object: ESXAPIClient instance
        @param client_object: ESXAPIClient instance

        @type attribute: str
        @param attribute: name or vmx as a string

        @type attribute_list: list
        @param attribute_list: List of VM names or VMX paths

        @rtype: list
        @return: List of vim.VirtualMachine instance
        """
        vm_list = cls.get_vm_list(client_object)
        if attribute == "name":
            vm_by_attribute = [vm for vm in vm_list if vm.name
                               in attribute_list]
            return vm_by_attribute
        elif attribute == "vmx":
            vm_by_attribute = [vm for vm in vm_list if
                               vm.summary.config.vmPathName in attribute_list]
            return vm_by_attribute
        else:
            raise Exception("Invalid argument for var attribute, expected"
                            " name or vmx, got %s" % attribute)
