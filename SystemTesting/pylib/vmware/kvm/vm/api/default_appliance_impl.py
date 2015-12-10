import vmware.common.global_config as global_config
import vmware.interfaces.appliance_interface as appliance_interface

pylogger = global_config.pylogger


class DefaultApplianceImpl(appliance_interface.ApplianceInterface):
    """Impl class for Appliance related Appliance operations."""

    MANAGEMENT_BRIDGE = "breth0"

    @classmethod
    def get_management_mac(cls, client_object):
        ''' Method to get_control_vif_mac of this vm

        '''
        vm = client_object.vm
        pylogger.debug("calling get_control_vif_mac operation on %s" % vm.name)
        vifs = vm.VIFs
        for vif in vifs:
            bridge = vif.get_bridge()
            if bridge == DefaultApplianceImpl.MANAGEMENT_BRIDGE:
                return vif.get_mac()
        pylogger.warn("Returing None from get_management_mac")

    @classmethod
    def get_management_ip(self, client_object):
        ''' Method to get_management_ip of this vm

        '''
        vm = client_object.vm
        ret = vm.get_ip()
        if not ret:
            pylogger.warn("Did not get management ip on VM %r on host %r" %
                          (vm.unique_name, client_object.kvm.ip))
        pylogger.debug("VM %r on host %r got management ip %r" %
                       (vm.unique_name, client_object.kvm.ip, ret))
        return ret

    @classmethod
    def get_management_ipv6(cls, client_object):
        """
        Method to get IPv6 address of the management interface of a VM.
        """
        vm = client_object.vm
        mgmt_iface = vm.management_vif.linux_device
        if not mgmt_iface:
            pylogger.error("Failed to get management interface for %r" %
                           vm.unique_name)
            return False
        ret = vm.host.get_link_local_ipv6(mgmt_iface)
        if not ret:
            pylogger.warn("Did not get IPv6 address for %s %s on host %r" %
                          (vm.unique_name, mgmt_iface, client_object.kvm.ip))
        return ret
