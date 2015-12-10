import vmware.common.global_config as global_config
import vmware.interfaces.power_interface as power_interface
import vmware.kvm.virsh as virsh

pylogger = global_config.pylogger


class DefaultPowerImpl(power_interface.PowerInterface):
    """
    Class for doing the power operation on a VM.

    All the operations here are done using virsh by passing commands to the KVM
    hypervisor object.
    """

    # TODO(Salman): It seems like a good candidate for abstraction too.
    @classmethod
    def _execute_vm_cmd(cls, operation, client_object):
        """
        Helper for formulating a virsh command, executing and logging it.

        @type operation: str
        @param operation: Power operation to perform on the VM.
        @type client_object: BaseClient
        @param client_object: Client object that is used to pass the
            commands to the parent host.
        @rtype: NoneType
        @return: None
        """
        cmd = virsh.Virsh.get_virsh_vm_cmd(operation, client_object.name)
        # XXX(Salman): The ssh connection object is not returning stderr as of
        # now!
        out = client_object.connection.request(cmd).response_data
        pylogger.info('%r operation result on %r: %r' %
                      (operation, client_object.name, out))

    @classmethod
    def on(cls, client_object):
        """
        Powers on the VM.

        @type client_object: BaseClient
        @param client_object: Client object that is used to pass the
            commands to the parent host.
        @rtype: NoneType
        @return: None
        """
        return cls._execute_vm_cmd(virsh.VirshCommand.START, client_object)

    @classmethod
    def off(cls, client_object):
        """
        Powers off the VM.

        @type client_object: BaseClient
        @param client_object: Client object that is used to pass the
            commands to the parent host.
        @rtype: NoneType
        @return: None
        """
        return cls._execute_vm_cmd(virsh.VirshCommand.OFF, client_object)

    @classmethod
    def reboot(cls, client_object):
        """
        Reboots the VM.

        @type client_object: BaseClient
        @param client_object: Client object that is used to pass the
            commands to the parent host.
        @rtype: NoneType
        @return: None
        """
        return cls._execute_vm_cmd(virsh.VirshCommand.REBOOT, client_object)

    @classmethod
    def shutdown(cls, client_object):
        """
        Shuts down the VM.

        @type client_object: BaseClient
        @param client_object: Client object that is used to pass the
            commands to the parent host.
        @rtype: NoneType
        @return: None
        """
        return cls._execute_vm_cmd(virsh.VirshCommand.SHUTDOWN, client_object)

    @classmethod
    def reset(cls, client_object):
        """
        Resets the VM.

        @type client_object: BaseClient
        @param client_object: Client object that is used to pass the
            commands to the parent host.
        @rtype: NoneType
        @return: None
        """
        return cls._execute_vm_cmd(virsh.VirshCommand.RESET, client_object)
