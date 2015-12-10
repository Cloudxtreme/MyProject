import vmware.common.result as result
import vmware.interfaces.power_interface as power_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.constants as constants
import vmware.common.global_config as global_config

pylogger = global_config.pylogger

REBOOT_TIMEOUT = constants.Timeout.HOST_REBOOT_MAX
TASK_COMPLETION_TIMEOUT = constants.Timeout.VIMTASK_COMPLETION
MAINTENANCE_MODE_TIMEOUT = constants.Timeout.ESX_ENTER_MAINT_MODE


class ESX55PowerImpl(power_interface.PowerInterface):
    """Hypervisor related power operations."""

    @classmethod
    def wait_for_reboot(cls, client_object):
        raise NotImplementedError

    @classmethod
    def async_reboot(cls, client_object, force=False):
        """
        Reboots a hypervisor.

        @type client_object: client instance
        @param client_object: Hypervisor client object

        @rtype: NoneType
        @return: None
        """
        host_mor = client_object.get_host_mor()
        host_mor.RebootHost_Task(force=force)

    @classmethod
    def reboot(cls, client_object, force=False):
        """
        Reboots a hypervisor.

        @type client_object: client instance
        @param client_object: Hypervisor client object

        @rtype: str
        @return: Result of reboot operation.
        """
        host_mor = client_object.get_host_mor()
        return vc_soap_util.get_task_state(
            host_mor.RebootHost_Task(force=force))

    @classmethod
    def enter_maintenance_mode(
            cls, client_object, timeout=None,
            evacuate_poweredoff_vm=False, maintenance_spec=None):
        """
        Forces the host to enter maintenance mode.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type timeout: int
        @param timeout: Timeout value for operation

        @type evacuate_poweredoff_vm: bool
        @param evacuate_poweredoff_vm: This parameter is only supported by VC.
             If set to true, for a DRS disabled cluster, the task will not
            succeed unless all powered-off virtual machines have been manually
            reregistered; for a DRS enabled cluster, VirtualCenter will
            automatically reregister powered-off virtual machines and a
            powered-off virtual machine may remain at the host only for two
            reasons: (a) no compatible host found for reregistration, (b) DRS
            is disabled for the virtual machine. If set to false, powered-off
            virtual machines do not need to be moved.

        @type maintenance_spec: HostMaintenanceSpec instance
        @param maintenance_spec: Addition actions to be specified.
        """
        host_mor = client_object.get_host_mor()
        if timeout is None:
            timeout = MAINTENANCE_MODE_TIMEOUT
        return vc_soap_util.get_task_state(host_mor.EnterMaintenanceMode_Task(
            timeout, evacuate_poweredoff_vm, maintenance_spec))

    @classmethod
    def exit_maintenance_mode(cls, client_object, timeout=None):
        """
        Removes the host from maintenance mode.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type timeout: int
        @param timeout: Timeout calue for operation.

        @rtype: str
        @return: Result of operation.
        """
        host_mor = client_object.get_host_mor()
        if timeout is None:
            timeout = MAINTENANCE_MODE_TIMEOUT
        return vc_soap_util.get_task_state(host_mor.ExitMaintenanceMode_Task(
            timeout))

    @classmethod
    def shutdown(cls, client_object, force=False):
        """Shuts down a host.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: str
        @return: Result of shutdown operation.
        """
        host_mor = client_object.get_host_mor()
        return vc_soap_util.get_task_state(
            host_mor.ShutdownHost_Task(force=force))

    @classmethod
    def on(cls, client_object):
        raise NotImplementedError

    @classmethod
    def off(cls, client_object):
        raise NotImplementedError

    @classmethod
    def reset(cls, client_object):
        raise NotImplementedError
