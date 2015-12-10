import vmware.common.constants as constants


class VirshCommand(constants.Constant):
    """Virsh commands for KVM"""
    VIRSH = 'virsh'
    START = "start"
    OFF = "destroy"
    REBOOT = "reboot"
    SHUTDOWN = "shutdown"
    RESET = "reset"


class Virsh(object):
    """
    Class to provide helper methods that can be reused in implementing
    KVM related operations.
    """

    @classmethod
    def get_virsh_vm_cmd(cls, command, vm_id, args=None):
        """
        Helper method for formulating a command.

        command: Operation to perfom on VM (e.g. 'start')
        vm_id: Domain ID (e.g. 'vm44de')
        args: Optional list of arguments for the command (e.g. ['--force-boot',
            '--console'])

        The output with the above examples will return a command like:
            'virsh start vm44de --force-boot --console'
        """
        cmd = [VirshCommand.VIRSH, command, vm_id]
        # TODO(Salman): Use mh.lib.common.utilities.as_list
        if args:
            if not isinstance(args, list):
                raise ValueError('Expected "args" to be a list, got %r '
                                 'instead' % args)
            cmd.extend(args)
        return ' '.join(cmd)
