import vmware.common.global_config as global_config
import vmware.interfaces.power_interface as power_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util

pylogger = global_config.pylogger


class VM10PowerImpl(power_interface.PowerInterface):
    """Impl class for VM power operations."""

    @classmethod
    def _do_power_action(cls, task):
        """
        Helper method to wait for task completion and return result.

        This method takes in the task object and waits till the
        task is completed and returns the result of the task.

        @type task: instance
        @param task: Task object.

        @rtype: str
        @return: The result of the power operation performed.
        """
        if task is None:
            return
        result = vc_soap_util.get_task_state(task)
        return result

    @classmethod
    def reboot(cls, client_object):
        """
        Performs reboot operation on the VM.

        The method calls the helper method that performs the
        operation and returns the result of the operation.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: NoneType
        @return: None.
        """
        # TODO: This function has not been tested yet as even with
        # VMware tools intalled on the guest, it throws an error saying
        # tools not found. VMware tools most probably remains to be
        # upgraded but upgrade was failing, so this function needs to
        # be tested.
        vm_mor = client_object.get_api()
        cls._do_power_action(vm_mor.RebootGuest())

    @classmethod
    def enter_maintenance_mode(cls, host, anchor=None):
        raise NotImplementedError("STUB")

    @classmethod
    def on(cls, client_object):
        """
        Performs power-on operation on the VM.

        The method calls the helper method that performs the
        operation and returns the result of the operation.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @return: The result of power-on operation.
        """
        vm_mor = client_object.get_api()
        return cls._do_power_action(vm_mor.PowerOnVM_Task())

    @classmethod
    def off(cls, client_object):
        """
        Performs power-off operation on the VM.

        The method calls the helper method that performs the
        operation and returns the result of the operation.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @return: The result of power-off operation.
        """
        vm_mor = client_object.get_api()
        return cls._do_power_action(vm_mor.PowerOffVM_Task())

    @classmethod
    def reset(cls, client_object):
        """
        Performs reset operation on the VM.

        The method calls the helper method that performs the
        operation and returns the result of the operation.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @return: The result of reset operation.
        """
        vm_mor = client_object.get_api()
        return cls._do_power_action(vm_mor.ResetVM_Task())

    @classmethod
    def shutdown(cls, client_object):
        """
        Performs shutdown operation on the VM.

        The method calls the helper method that performs the
        operation and returns the result of the operation.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: NoneType
        @return: None.
        """
        # TODO: This function has not been tested yet, as even with
        # VMware tools intalled on the guest, it throws an error saying
        # tools not found. VMware tools most probably needs to be
        # upgraded but upgrade was failing, so this function remains to
        # be tested.
        vm_mor = client_object.get_api()
        cls._do_power_action(vm_mor.ShutdownGuest())

    @classmethod
    def get_power_state(cls, client_object):
        """
        get_power_state() returns the power state of the VM.

        The method makes an API call that returns the current
        power state of the VM.

        @type client_object: instance
        @param client_object: VMAPIClient object.

        @rtype: str
        @return: The current power state of the VM.
        """
        vm_mor = client_object.get_api()
        return vm_mor.runtime.powerState
