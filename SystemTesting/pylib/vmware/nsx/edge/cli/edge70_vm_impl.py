import vmware.common.global_config as global_config
import vmware.interfaces.vm_interface as vm_interface
import vmware.vsphere.esx.esx_facade as esx_facade
import vmware.vsphere.vm.vm_facade as vm_facade

pylogger = global_config.pylogger


class Edge70VMImpl(vm_interface.VMInterface):

    """NSX edge related VM operations."""

    @classmethod
    def get_cpu_count(cls, client_object, vm_ip_address=None,
                      esx_host_ip=None, esx_username=None,
                      esx_password=None, **kwargs):
        """
        Fetches the CPU COUNT for given VM IP Addr

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the CPU count using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: int
        @param: CPU Count
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_cpu_count = vm.get_cpu_count()

        pylogger.debug("actual_cpu_count retrieved ...%s ", actual_cpu_count)

        pydict = {'expected_cpu_count': actual_cpu_count}
        return pydict

    @classmethod
    def get_nic_count(cls, client_object, vm_ip_address=None,
                      esx_host_ip=None, esx_username=None,
                      esx_password=None, **kwargs):
        """
        Fetches the NIC COUNT for given VM IP Addr

        The method uses the ESX ip and credentials to create the
        ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the NIC Count using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: int
        @param: NIC Count
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_nic_count = vm.get_nic_count()

        pylogger.debug("actual_nic_count retrieved ...%s ", actual_nic_count)

        pydict = {'expected_nic_count': actual_nic_count}
        return pydict

    @classmethod
    def get_virtual_disk_count(cls, client_object, vm_ip_address=None,
                               esx_host_ip=None, esx_username=None,
                               esx_password=None, **kwargs):
        """
        Fetches the VIRTUAL DISK COUNT for given VM IP Addr

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the Disk Count using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: int
        @param: Virtual Disk Count
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_virtual_disk_count = vm.get_virtual_disk_count()

        pylogger.debug("actual_virtual_disk_count retrieved ...%s ",
                       actual_virtual_disk_count)

        pydict = {'expected_virtual_disk_count': actual_virtual_disk_count}
        return pydict

    @classmethod
    def get_mem_size(cls, client_object, vm_ip_address=None,
                     esx_host_ip=None, esx_username=None,
                     esx_password=None, **kwargs):
        """
        Fetches the MEMORY SIZE for given VM IP Addr

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the Memory Size using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Memory Size
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_mem_size = vm.get_mem_size()

        pylogger.debug("actual_mem_size retrieved ...%s ", actual_mem_size)

        pydict = {'expected_mem_size': actual_mem_size}
        return pydict

    @classmethod
    def get_nic_type(cls, client_object, vm_ip_address=None,
                     vnic_index=None, esx_host_ip=None,
                     esx_username=None, esx_password=None, **kwargs):
        """
        Fetches the NIC TYPE for given VM IP Addr and vnic_index

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the NIC Type for the given index using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: NIC Type
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_nic_type = vm.get_nic_type(vnic_index=int(vnic_index))

        pylogger.debug("actual_nic_type retrieved ...%s ", actual_nic_type)

        pydict = {'expected_nic_type': actual_nic_type}
        return pydict

    @classmethod
    def get_disk_size(cls, client_object, vm_ip_address=None,
                      disk_index=None, esx_host_ip=None, esx_username=None,
                      esx_password=None, **kwargs):
        """
        Fetches the VIRTUAL DISK SIZE for given VM IP Addr and disk_index

        The method uses the ESX ip and credentials to create the
        ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the Disk Size for the given index using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Disk Size
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_disk_size = vm.get_disk_size(disk_index=int(disk_index))

        pylogger.debug("actual_nic_count retrieved ...%s ", actual_disk_size)

        pydict = {'expected_disk_size': actual_disk_size}
        return pydict

    @classmethod
    def get_max_memory_usage(cls, client_object, vm_ip_address=None,
                             esx_host_ip=None, esx_username=None,
                             esx_password=None, **kwargs):
        """
        Fetches the MAX Memory value for given VM IP Addr

        The method uses the ESX ip and credentials to create the
        ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the Maximum Memory Usage for the given moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Maximum Memory Usage
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_max_mem_usage = vm.get_max_memory_usage()

        pylogger.debug("actual_max_mem_usage retrieved ...%s ",
                       actual_max_mem_usage)

        pydict = {'expected_max_mem_usage': actual_max_mem_usage}
        return pydict

    @classmethod
    def get_max_cpu_usage(cls, client_object, vm_ip_address=None,
                          esx_host_ip=None, esx_username=None,
                          esx_password=None, **kwargs):
        """
        Fetches the MAX CPU value for given VM IP Addr

        The method uses the ESX ip and credentials to create the ESX
        managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the Maximum CPU Usage for the given moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Maximum CPU Usage
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_max_cpu_usage = vm.get_max_cpu_usage()

        pylogger.debug("actual_max_cpu_usage retrieved ...%s ",
                       actual_max_cpu_usage)

        pydict = {'expected_max_cpu_usage': actual_max_cpu_usage}
        return pydict

    @classmethod
    def get_tools_running_status(cls, client_object, vm_ip_address=None,
                                 esx_host_ip=None, esx_username=None,
                                 esx_password=None, **kwargs):
        """
        Fetches the VM Tools Running status for given VM IP Addr

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the VMTools Running Status using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: VMTools Running Status
        """

        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_tools_running_status = vm.get_tools_running_status().\
            strip().lower()

        pylogger.debug("actual_tools_running_status retrieved ...%s ",
                       actual_tools_running_status)

        pydict = {'expected_tools_running_status': actual_tools_running_status}
        return pydict

    @classmethod
    def get_nic_status(cls, client_object, vm_ip_address=None,
                       vnic_index=None, esx_host_ip=None, esx_username=None,
                       esx_password=None, **kwargs):
        """
        Fetches the NIC STATUS for given VM IP Addr and vnic_index

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_ip_address
        Thereafter it fetches the NIC Status for the given index using the moid
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: NIC Status
        """
        hc = esx_facade.ESXFacade(esx_host_ip, esx_username, esx_password)
        edge_moid = hc.fetch_moid_from_ip(vm_ip_address=vm_ip_address)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        actual_nic_status = vm.get_nic_status(vnic_index=int(vnic_index))

        pylogger.debug("actual_nic_status retrieved ...%s ", actual_nic_status)

        pydict = {'expected_nic_status': actual_nic_status}
        return pydict

    @classmethod
    def get_guest_net_info(cls, client_object, vm_name=None,
                           host_ip=None, username=None,
                           password=None, **kwargs):
        """
        Fetches guest net info for given VM name

        The method uses the ESX ip and credentials to create
        the ESX managed object reference.
        Next it uses the ESX mor to fetch MOID of given vm_name
        Finally returns the fetched value to calling method

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: table
        @param: guest net info table
        """

        hc = esx_facade.ESXFacade(host_ip, username, password)
        edge_moid = hc.fetch_vm_mor_from_name(vm_name=vm_name)

        vm = vm_facade.VMFacade(edge_moid, parent=hc)
        return vm.get_guest_net_info()
