import vmware.workarounds as workarounds
import vmware.common.global_config as global_config
import vmware.common.timeouts as timeouts
import vmware.interfaces.power_interface as power_interface

pylogger = global_config.pylogger
MONITOR_SOCKET_ERROR = ("monitor socket did not show up.: No such file or "
                        "directory")
OVS_PORT_CREATE_ERROR = "Unable to add port"


class DefaultPowerImpl(power_interface.PowerInterface):
    """Impl class for VM power operations."""

    POWERED_ON = "poweredon"
    POWERED_OFF = "poweredoff"

    @classmethod
    def on(cls, client_object):
        ''' Method to power on the vm
        '''
        vm = client_object.vm

        def power_on_exc_handler(exc):
            # exc.args is a tuple, use '== exc.args[0]' when matching the whole
            # string and 'in exc.args[0]' for matching partial strings
            if ((MONITOR_SOCKET_ERROR == exc.args[0] or
                 OVS_PORT_CREATE_ERROR in exc.args[0])):
                pylogger.debug("%r: Retrying vm start up on error: %r" %
                               (vm.name, exc))
            else:
                pylogger.error("%r: VM power on failed with %r" %
                               (vm.name, exc))
                raise

        def power_on_ret_checker(ret):
            # Start method doesn't return anything just throws libvirtError on
            # power on failures
            return True

        if workarounds.kvm_vm_power_on_retry_workaround.enabled:
            pylogger.debug("%r: Powering on VM using timeout" % vm.name)
            return timeouts.kvm_vm_power_on_retry_timeout.wait_until(
                vm.start, checker=power_on_ret_checker,
                exc_handler=power_on_exc_handler)
        else:
            pylogger.debug("%r: Powering on VM" % vm.name)
            return vm.start()

    @classmethod
    def off(cls, client_object):
        ''' Method to power off the vm
        '''
        vm = client_object.vm
        pylogger.debug("calling off operation on %s" % vm.name)
        return vm.stop()

    @classmethod
    def get_power_state(cls, client_object):
        ''' Method to get power state of the vm
        '''
        pylogger.info("client_object in get_power_state %s" % client_object)
        vm = client_object.vm
        state = vm.get_state()
        pylogger.debug("calling get_power_state gave %s " % state)
        if state == 1:
            return DefaultPowerImpl.POWERED_ON
        if state == 5:
            return DefaultPowerImpl.POWERED_OFF
