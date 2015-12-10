import vmware.common.global_config as global_config
import vmware.interfaces.vm_interface as vm_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.schema.guest_schema as guest_schema
import vmware.schema.guest_net_info_table_schema as guest_net_info_schema
import vmware.common.constants as constants

import time
import pyVmomi as pyVmomi
import socket

vim = pyVmomi.vim
GuestSchema = guest_schema.GuestSchema
pylogger = global_config.pylogger
RUNNING = "guestToolsRunning"
EXECUTING = "guestToolsExecutingScripts"
ADD = "add"
REMOVE = "remove"


class VM10VMImpl(vm_interface.VMInterface):
    """Impl class for VM operations."""

    @classmethod
    def _wait_for_task(cls, task):
        """
        Helper function to wait for task completion and log results.

        The method takes in the task object returned by the API and
        waits till the task has been completed to log the result.

        @type task: instance
        @param task: Task object returned by API.

        @rtype: str
        @return: Status of the operation
        """
        result = vc_soap_util.get_task_state(task)
        return result

    @classmethod
    def suspend(cls, client_object):
        """
        Performs suspend operation on a VM.

        The method takes the client object as an argument and makes
        a call to the API to perform the suspend operation.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @return: A str that describes the result (success/error).
        """
        vm_mor = client_object.get_api()
        task = vm_mor.SuspendVM_Task()
        return cls._wait_for_task(task)

    @classmethod
    def create_snapshot(cls, client_object, name=None, description=None,
                        memory=False, quiesce=False):
        """
        Creates a snapshot corresponding to the snapshot name.

        The method takes in snapshot information and makes a call
        to the API to create a snapshot of the current state.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @type name: str
        @param name: Optional argument to specify the snapshot name.
        @type description: str
        @param description: Optional argument to describe the snapshot.
        @type memory: bool
        @param memory: If True, then includes internal state of VM.
        @type quiesce: bool
        @param quiesce: If True and VM is on, VMware tools is used to
               quiesce the file system in the VM.

        @rtype: str
        @return: The result of the create snapshot operation.
        """
        vm_mor = client_object.get_api()
        task = vm_mor.CreateSnapshot_Task(
            name, description, memory, quiesce)
        return cls._wait_for_task(task)

    @classmethod
    def remove_snapshot(cls, client_object, snapshot_name=None,
                        remove_children=False, consolidate=True):
        """
        Removes the snapshot and deletes associated storage.

        The method removes an existing snapshot corresponding
        to the snapshot name.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @type snapshot_name: str
        @param snapshot_name: Snapshot name.

        @type remove_children: bool
        @param remove_children: If True, removes snapshot subtree.

        @type consolidate: bool
        @param consolidate: If True, virtual disk associated with
               snapshot is merged with other disk if possible.

        @rtype: str
        @return: The result of the remove snapshot operation.
        """
        vm_mor = client_object.get_api()
        snapshot_list = vm_mor.snapshot.rootSnapshotList
        for my_snapshot in snapshot_list:
            if snapshot_name == my_snapshot.name:
                snapshot_mor = my_snapshot.snapshot
                task = snapshot_mor.RemoveSnapshot_Task(
                    remove_children, consolidate)
                return cls._wait_for_task(task)
            else:
                for child_snapshot in my_snapshot.childSnapshotList:
                    if snapshot_name == child_snapshot.name:
                        snapshot_mor = child_snapshot.snapshot
                        task = snapshot_mor.RemoveSnapshot_Task(
                            remove_children, consolidate)
                        return cls._wait_for_task(task)

    @classmethod
    def revert_to_current_snapshot(cls, client_object, host=None,
                                   supress_power_on=False):
        """
        Reverts the state of the VM to the current snapshot.

        The method performs an API call to revert the state of the
        VM to the current existing snapshot.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @type host: instance
        @param host: Host managed object reference.

        @type supress_power_on: bool
        @param supress_power_on: If True, VM will not be powered
               on regardless of the power state.

        @rtype: str
        @return: The result of revert to current snapshot operation.
        """
        vm_mor = client_object.get_api()
        if host is None:
            host = client_object.get_parent()
        task = vm_mor.RevertToCurrentSnapshot_Task(
            host, supress_power_on)
        return cls._wait_for_task(task)

    @classmethod
    def revert_to_snapshot(cls, client_object, snapshot_name=None, host=None,
                           supress_power_on=False):
        """
        Reverts the state of the VM to the snapshot provided by user.

        The method makes an API call that reverts the state of the
        VM to a snapshot corresponding to the snapshot name.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @type snapshot_name: str
        @param snapshot_name: Name of snapshot.

        @type host: instance
        @param host: Host managed object reference.

        @type supress_power_on: bool
        @param supress_power_on: If True, VM will not be powered
               on regardless of the power state.

        @rtype: str
        @return: The result of the revert to snapshot operation.
        """
        if host is None:
            host = client_object.get_parent()
        vm_mor = client_object.get_api()
        snapshot_list = vm_mor.snapshot.rootSnapshotList
        for my_snapshot in snapshot_list:
            if snapshot_name == my_snapshot.name:
                snapshot_mor = my_snapshot.snapshot
                task = snapshot_mor.RevertToSnapshot_Task(
                    host, supress_power_on)
                return cls._wait_for_task(task)
            else:
                for child_snapshot in my_snapshot.childSnapshotList:
                    if snapshot_name == child_snapshot.name:
                        snapshot_mor = child_snapshot.snapshot
                        task = snapshot_mor.RevertToSnapshot_Task(
                            host, supress_power_on)
                        return cls._wait_for_task(task)

    @classmethod
    def upgrade_tools(cls, client_object, installer_options=None):
        """
        Begins the tools upgrade process.

        The method makes a call to the API to perform upgrade
        operation on the tools.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @type installer_options: str
        @param installer_options: Command line options to modify
               installation procedure.

        @rtype: str
        @return: The result of the upgrade tools task.
        """
        # Example for installer options
        # Setup.exe /s /v"/qn /l*v ""%TEMP%\vmmsi.log"""
        vm_mor = client_object.get_api()
        task = vm_mor.UpgradeTools_Task(installer_options)
        return cls._wait_for_task(task)

    @classmethod
    def mount_tools_installer(cls, client_object):
        """
        Mounts the VMware tools CD installer on the guest OS.

        The method makes an API call to mount the VMware tools
        installer as a CD-ROM for the guest OS.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: NoneType
        @return None.
        """
        vm_mor = client_object.get_api()
        vm_mor.MountToolsInstaller()

    @classmethod
    def check_tools_mounting_status(cls, client_object):
        """
        Checks the current status of VMware tools installed on the guest.

        @type client_object: VMAPIClient instance
        @param client_object: VMAPIClient instance

        @rtype: str
        @return: Success or Failure
        """
        vm_mor = client_object.get_api()
        wait_time = 120
        start_time = time.time()
        while(time.time() - start_time < wait_time):
            if vm_mor.guest.toolsRunningStatus == RUNNING:
                return constants.Result.SUCCESS
            elif vm_mor.guest.toolsRunningStatus == EXECUTING:
                pylogger.info("VMware tools is starting")
                time.sleep(10)
                continue
            else:
                return constants.Result.FAILURE
        pylogger.error("Operation timed out")
        return constants.Result.FAILURE

    @classmethod
    def unmount_tools_installer(cls, client_object):
        """
        Unmounts the VMware tools CD installer.

        The method makes an API call to unmount the VMware tools
        installer on the guest OS.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: NoneType
        @return None.
        """
        vm_mor = client_object.get_api()
        vm_mor.UnmountToolsInstaller()

    # TODO: Choose default folder to register VM. Current default
    # is set to vm-folder."""
    @classmethod
    def register_vm(cls, client_object, folder=None, path=None,
                    name=None, as_template=False, pool=None, host=None):
        """
        Adds an existing VM to the folder.

        The method makes an API call that register the VM to
        the appropriate folder specified by the client.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @type folder: instance
        @param folder: Name of folder.

        @type name: str
        @param name: Name to be assigned to VM.

        @type as_template: bool
        @param as_template: Specifies if VM is marked as template.

        @type pool: instance
        @param pool: Resource pool to which VM is to be attached.

        @type host: instance
        @param host: Managed object reference of target host.

        @rtype: str
        @return: The result of the register VM operation.
        """
        if host is None:
            host = client_object.get_parent()
        if folder is None:
            ha_compute = host.parent
            pool = ha_compute.resourcePool
            ha_datacenter = host
            while(isinstance(ha_datacenter, pyVmomi.vim.Datacenter) is False):
                ha_datacenter = ha_datacenter.parent
            folder = ha_datacenter.vmFolder
        task = folder.RegisterVM_Task(path, name,
                                      as_template, pool, host)
        return cls._wait_for_task(task)

    @classmethod
    def unregister_vm(cls, client_object):
        """
        Removes the VM from the inventory without removing its
        files on disk.

        The method makes an API call that removes that removes the
        VM from the inventory but keeps the VM's files on disk.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: NoneType
        @return: None.
        """
        vm_mor = client_object.get_api()
        vm_mor.UnregisterVM()

    @classmethod
    def get_vm_spec_path(cls, client_object):
        """
        Queries the vmx file path for a VM.

        The method uses the VM managed object reference to
        query the vmx file path for the VM.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @return: The vmx file path of the VM.
        """
        vm_mor = client_object.get_api()
        return vm_mor.summary.config.vmPathName

    @classmethod
    def get_guest_info(cls, client_object):
        """
        Queries information about the guest running on the VM.

        The method is used to query information about the guest
        using the VM managed object reference.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: instance
        @return: GuestInfo instance.
        """
        vm_mor = client_object.get_api()
        return GuestSchema(
            name=vm_mor.guest.guestFullName,
            family=vm_mor.guest.guestFamily,
            guest_id=vm_mor.guest.guestId,
            state=vm_mor.guest.guestState,
            hostname=vm_mor.guest.hostName,
            ip=vm_mor.guest.ipAddress)

    @classmethod
    def get_guest_net_info(cls, client_object, timeout=None):
        """
        Queries all net information on the VM.

        The method is used to query all net information
        using the VM managed object reference.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: table
        @return: guest net table
        """
        vm_mor = client_object.get_api()
        py_dict = {}
        py_dict_node = {}
        node_data = []
        if timeout is None:
            timeout = 180
        start_time = time.time()
        while(time.time() - start_time < timeout):
            for guestNicInfo in vm_mor.guest.net:
                if guestNicInfo.ipAddress is not None:
                    ipv4 = []
                    ipv6 = []
                    for ip in guestNicInfo.ipAddress:
                        try:
                            socket.inet_aton(ip)
                            # it's a ipv4 address
                            ipv4.append(ip)
                        except socket.error:
                            # ipv6 address
                            ipv6.append(ip)
                mac = guestNicInfo.macAddress
                device_label = None
                network = None
                for device in vm_mor.config.hardware.device:
                    if device.key == guestNicInfo.deviceConfigId:
                        device_label = device.deviceInfo.label
                        portgroup = network = device.deviceInfo.summary
                        temp = (((str)(type(device)).split("'"))[1])
                        adapter_class = temp.split("device.")[1]
                        break
                py_dict_node = {'device_label': device_label,
                                'mac': mac,
                                'ipv4_array': ipv4,
                                'ipv6_array': ipv6,
                                'network': network,
                                'portgroup': portgroup,
                                'adapter_class': adapter_class}
                node_data.append(py_dict_node)
            if len(node_data) != 0:
                break
        if len(node_data) == 0:
            pylogger.error("Could not find any guest_nic_info")
            return constants.Result.FAILURE.upper()

        py_dict['table'] = node_data
        return guest_net_info_schema.GuestNetInfoTableSchema(py_dict=py_dict)

    @classmethod
    def get_vm_hardware_info(cls, client_object):
        """
        Queries the VM hardware information.

        The method uses the VM managed object reference to
        extract the VM hardware information.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: instance
        @return: VirtualHardware instance.
        """
        vm_mor = client_object.get_api()
        return vm_mor.config.hardware

    @classmethod
    def check_device_connection_status(cls, client_object, device_name=None):
        """
        Checks the connection status of the virtual network adapter

        @type client_object: VMAPIClient instance
        @param client_object: VMAPIClient instance
        @type device_name: str
        @param device_name: Device name

        @rtype: bool
        @return: True if connected, False if not connected
        """
        vm_mor = client_object.get_api()
        for device in vm_mor.config.hardware.device:
            if device.deviceInfo.label == device_name:
                if device.connectable.connected is True:
                    return True
                else:
                    return False
        pylogger.error("Device %r not found" % device_name)

    @classmethod
    def configure_pci_passthrough(
            cls, client_object, key=None, device=None,
            controller_key=None, operation=None):
        """
        Adds or removes a pci passthrough for the VM.

        @type client_object: VMAPIClient instance
        @param client_object: VMAPIClient instance
        @type key: int
        @param key: A unique key that distinguishes this device from
            other devices in the same virtual machine.
        @type device: str
        @param device: Name of pnic, eg vmnic0
        @type controller_key: str
        @param controller_key: Object key for the controller object for this
            device. This property contains the key property value of the
            controller device object.
        @type operation: str
        @param operation: add or remove

        @rtype: str
        @param: Status of the operation
        """
        host_mor = client_object.parent.get_host_mor()
        network_sys = host_mor.configManager.networkSystem
        backing_spec = vim.vm.device.VirtualPCIPassthrough.DeviceBackingInfo()
        for pnic in network_sys.networkInfo.pnic:
            if pnic.device == device:
                pci = pnic.pci
                for pci_device in host_mor.hardware.pciDevice:
                    if pci_device.id == pci:
                        vm_mor = client_object.get_api()
                        config_spec = vim.vm.ConfigSpec()
                        device_spec = vim.vm.device.VirtualDeviceSpec()
                        device_spec.operation = operation
                        passthru = vim.vm.device.VirtualPCIPassthrough()
                        if operation == ADD:
                            backing_spec.deviceId = str(pci_device.deviceId)
                            backing_spec.id = pci
                            backing_spec.vendorId = pci_device.vendorId
                            uuid = host_mor.hardware.systemId.uuid
                            backing_spec.systemId = uuid
                            passthru.backing = backing_spec
                            passthru.controllerKey = controller_key
                            passthru.key = key
                            device_spec.device = passthru
                            config_spec.deviceChange = [device_spec]
                        elif operation == REMOVE:
                            passthru.key = key
                            device_spec.device = passthru
                            config_spec.deviceChange = [device_spec]
                        else:
                            raise Exception("Specifiy operation type")
                        try:
                            return vc_soap_util.get_task_state(
                                vm_mor.ReconfigVM_Task(config_spec))
                        except Exception as e:
                            raise Exception("Could not add passthrough", e)
        pylogger.error("Could not find %r" % device)

    @classmethod
    def get_name(cls, client_object):
        """
        Queries the VM Name.

        The method uses the VM managed object reference to
        extract the VM name.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Status of the operation
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return vm.name
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def rename_vm(cls, client_object, name=None):
        vm_mor = client_object.get_api()
        config_spec = vim.vm.ConfigSpec()
        config_spec.name = name
        try:
            return vc_soap_util.get_task_state(
                vm_mor.ReconfigVM_Task(config_spec))
        except Exception as e:
            raise Exception("Could not rename the vm", e)

    @classmethod
    def get_mem_size(cls, client_object):
        """
        Queries the RAM/Memory size for a given VM.

        The method uses the VM managed object reference to
        extract the VM RAM/Memory size.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: MEMORY SIZE
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return str(vm.config.hardware.memoryMB) + " MB"
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_cpu_count(cls, client_object):
        """
        Queries the CPU count for a given VM.

        The method uses the VM managed object reference to
        extract the number of CPUs in a given VM.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: int
        @param: CPU COUNT
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return vm.config.hardware.numCPU
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_nic_count(cls, client_object):
        """
        Queries the NIC count for a given VM.

        The method uses the VM managed object reference to
        extract the VM NIC/Interface count.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: int
        @param: NIC Count
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return vm.summary.config.numEthernetCards
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_virtual_disk_count(cls, client_object):
        """
        Queries the HDD/Virtual Disk count for a given VM.

        The method uses the VM managed object reference to
        extract the VM HDD/VirtualDisk count.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: int
        @param: Virtual Disk Count
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return vm.summary.config.numVirtualDisks
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_max_cpu_usage(cls, client_object):
        """
        Queries the MaxCpuUsage for a given VM.

        The method uses the VM managed object reference to
        extract the VM MaxCpuUsage.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Maximum CPU Usage
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return str(vm.summary.runtime.maxCpuUsage) + " MHz"
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_max_memory_usage(cls, client_object):
        """
        Queries the MaxMemoryUsage for a given VM.

        The method uses the VM managed object reference to
        extract the VM MaxMemoryUsage.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Maximum Memory Usage
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return str(vm.summary.runtime.maxMemoryUsage) + " MB"
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_nic_type(cls, client_object, vnic_index=None):
        """
        Queries the Type of NIC for a given VM
        provided a nic_index is specified.

        The method uses the VM managed object reference to
        extract the NIC_type for a given index on a VM.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: NIC Type
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                for device in vm.config.hardware.device:
                    type_string = type(device).__name__.split(".")[-1]

                    if vnic_index == 1 and device.deviceInfo.label == \
                            "Network adapter 1":
                        return type_string
                    if vnic_index == 2 and device.deviceInfo.label == \
                            "Network adapter 2":
                        return type_string
                    if vnic_index == 3 and device.deviceInfo.label == \
                            "Network adapter 3":
                        return type_string

        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_disk_size(cls, client_object, disk_index=None):
        """
        Queries the Storage Available/Disk Size of a
        HDD for a given VM provided a disk index is specified.

        The method uses the VM managed object reference to
        extract the VM Storage Available/Disk Size of a .

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: Disk Size
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                for device in vm.config.hardware.device:
                    type_string = type(device).__name__.split(".")[-1]

                    if disk_index == 1 and device.deviceInfo.label == \
                            "Hard disk 1" and type_string == "VirtualDisk":
                        return str(device.capacityInKB/1024) + " MB"
                    if disk_index == 2 and device.deviceInfo.label == \
                            "Hard disk 2" and type_string == "VirtualDisk":
                        return str(device.capacityInKB/1024) + " MB"

        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_ip(cls, client_object):
        """
        Returns the management IP of the VM if VM is running else returns None.
        """
        vm_mor = client_object.get_api()
        if vm_mor.guest.guestState == 'running':
            return vm_mor.guest.ipAddress
        pylogger.warn('VM %r on host %r is not running, no IP found' %
                      (vm_mor.name, client_object.parent.ip))

    @classmethod
    def get_tools_running_status(cls, client_object):
        """
        Queries the VM Tools Running Status for a given VM .

        The method uses the VM managed object reference to
        extract the VM Tools Running Status of a VM.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: VMTools Running Status
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                return str(vm.summary.guest.toolsStatus)
        raise Exception("%s vm name not found" %
                        client_object.id_)

    @classmethod
    def get_nic_status(cls, client_object, vnic_index=None):
        """
        Queries the Status of NIC for a given VM
        provided a nic_index is specified.

        The method uses the VM managed object reference to
        extract the NIC_status for a given index on a VM.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @param: NIC Status
        """
        host_mor = client_object.parent.get_host_mor()
        for vm in host_mor.vm:
            if vm._moId == client_object.id_:
                for device in vm.config.hardware.device:

                    if vnic_index == 1 and device.deviceInfo.label == \
                            "Network adapter 1":
                        return device.connectable.connected
                    if vnic_index == 2 and device.deviceInfo.label == \
                            "Network adapter 2":
                        return device.connectable.connected
                    if vnic_index == 3 and device.deviceInfo.label == \
                            "Network adapter 3":
                        return device.connectable.connected
